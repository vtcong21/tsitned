----------------------------------
--ALL01/ XEM DANH MỤC THUỐC
GO
CREATE OR ALTER PROC SP_GETALLTHUOC_NV_QTV_NS
AS
BEGIN TRAN
	BEGIN TRY
		SELECT * FROM LOAITHUOC
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN;
		DECLARE @errorMessage NVARCHAR(200) = ERROR_MESSAGE();
		THROW 51000, @errorMessage, 1;
		RETURN
	END CATCH
COMMIT TRAN
---------------------
--ALL03/ TRUY VẤN HỒ SƠ KHÁM BỆNH
GO
CREATE OR ALTER PROC SP_GETHSB1KH_NV_NS_KH
	@SODT VARCHAR(100)
AS
BEGIN TRAN
	BEGIN TRY
		IF (NOT EXISTS(SELECT * FROM KHACHHANG WHERE SODT = @SODT))
		BEGIN
			RAISERROR(N'Khách hàng này không tồn tại', 16, 1);
			ROLLBACK TRAN
			RETURN
		END
		
		ELSE
		BEGIN
			SELECT HSB.SOTT, HSB.SODT SODT, KH.HOTEN HOTEN, DATEDIFF(year,KH.NGAYSINH,GETDATE()) TUOI, NGAYKHAM, NS.HOTEN NHASI, DANDO, CTDV.MADV, TENDV, CTDV.SOLUONG, CTT.MATHUOC, TENTHUOC, CTT.SOLUONG, DONVITINH, THOIDIEMDUNG
			FROM HOSOBENH HSB 
			JOIN NHASI NS ON HSB.MANS = NS.MANS
			JOIN KHACHHANG KH ON KH.SODT = HSB.SODT
			JOIN CHITIETDV CTDV ON CTDV.SOTT = HSB.SOTT AND CTDV.SODT = HSB.SODT
			JOIN LOAIDICHVU LDV ON LDV.MADV = CTDV.MADV
			LEFT JOIN CHITIETTHUOC CTT ON CTT.SOTT = HSB.SOTT AND CTT.SODT = HSB.SODT
			LEFT JOIN LOAITHUOC LT ON LT.MATHUOC = CTT.MATHUOC
			WHERE HSB.SODT = @SODT
		END
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN;
		DECLARE @errorMessage NVARCHAR(200) = ERROR_MESSAGE();
		THROW 51000, @errorMessage, 1;
		RETURN
	END CATCH
COMMIT TRAN
-------------------------------------------------------
--ALL05/ TẠO LỊCH HẸN
GO
CREATE OR ALTER PROC SP_DATLICHHEN_NV_KH
	@SODT VARCHAR(100),
	@MANS VARCHAR(100),
	@SOTT INT,
	@LYDOKHAM VARCHAR(200)
AS
BEGIN TRAN
	BEGIN TRY
		IF (EXISTS(SELECT * 
				   FROM LICHHEN
				   WHERE MANS = @MANS AND SOTT = @SOTT))
		BEGIN
			RAISERROR(N'Lỗi: Đã có khách hàng đặt lịch hẹn này.',16,1)
			ROLLBACK TRAN
			RETURN
		END

		IF (EXISTS(SELECT LH.*
				  FROM LICHHEN LH JOIN LICHRANH LR
 				  ON LH.MANS = LR.MANS AND LH.SOTT = LR.SOTT
				  WHERE EXISTS(SELECT *
			 	  			   FROM LICHRANH LR2
			 				   WHERE LR2.MANS != LH.MANS AND LR.NGAY = LR2.NGAY AND LR.MACA = LR2.MACA
			 				   AND LH.SODT = @SODT
			 				   AND LR2.SOTT = @SOTT
			 				   AND LR2.MANS = @MANS)))
		BEGIN
			RAISERROR(N'Lỗi: Các lịch hẹn của cùng một khách hàng không được trùng ca nhau.',16,1)
			ROLLBACK TRAN
			RETURN
		END

		ELSE
		BEGIN
			INSERT INTO LICHHEN(MANS, SODT, LYDOKHAM, SOTT) 
			VALUES(@MANS, @SODT, @LYDOKHAM, @SOTT)
		END
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN;
		DECLARE @errorMessage NVARCHAR(200) = ERROR_MESSAGE();
		THROW 51000, @errorMessage, 1;
		RETURN
	END CATCH
COMMIT TRAN
----------------------------------
--ALL06/ HỦY LỊCH HẸN
GO
CREATE OR ALTER PROC SP_DELETELICHEN_NV_KH
	@MANS VARCHAR(100),
	@SODT VARCHAR(100),
	@SOTT INT
AS
BEGIN TRAN
	BEGIN TRY
		IF (NOT EXISTS(SELECT * FROM LICHHEN WHERE SODT = @SODT AND MANS = @MANS AND SOTT = @SOTT))
		BEGIN
			RAISERROR(N'Lịch hẹn này không tồn tại', 16, 1);
			ROLLBACK TRAN
			RETURN
		END
		IF (EXISTS(SELECT * 
		FROM LICHHEN LH
		JOIN LICHRANH LR ON LH.MANS = LR.MANS AND LH.MANS = LR.MANS
		WHERE SODT = @SODT AND LH.MANS = @MANS AND LH.SOTT = @SOTT AND DATEDIFF(DAY,GETDATE(),NGAY) <= 1))
		BEGIN
			RAISERROR(N'Không thể hủy lịch hẹn trước 1 ngày', 16, 1);
			ROLLBACK TRAN
			RETURN
		END
		ELSE
		BEGIN
			DELETE 
			FROM LICHHEN
			WHERE MANS = @MANS AND SOTT = @SOTT
		END
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN;
		DECLARE @errorMessage NVARCHAR(200) = ERROR_MESSAGE();
		THROW 51000, @errorMessage, 1;
		RETURN
	END CATCH
COMMIT TRAN

----------------------------------
--ALL04/ ĐĂNG NHẬP
GO
CREATE OR ALTER PROC SP_DANGNHAP_ALL
	@MATK VARCHAR(100),
	@MATKHAU VARCHAR(20)
AS
BEGIN TRAN
	BEGIN TRY
		IF LEN(@MATK) > 10
		BEGIN
			RAISERROR(N'Tải khoản đăng nhập không hợp lệ.')
			ROLLBACK TRAN
			RETURN
		END 

		DECLARE @ROLE VARCHAR(10);
		SET @ROLE = NULL;

		--Kiểm tra tài khoản đăng nhập có hợp lệ không
		IF EXISTS (SELECT * FROM KHACHHANG WHERE SODT = @MATK AND MATKHAU = @MATKHAU)
		BEGIN
			SET @ROLE = 'KH';
		END
		ELSE IF EXISTS (SELECT * FROM NHASI WHERE MANS = @MATK AND MATKHAU = @MATKHAU)
		BEGIN
			SET @ROLE = 'NS';
		END
		ELSE IF EXISTS (SELECT * FROM NHANVIEN WHERE MANV = @MATK AND MATKHAU = @MATKHAU)
		BEGIN
			SET @ROLE = 'NV';
		END
		ELSE IF EXISTS (SELECT * FROM QTV WHERE MAQTV = @MATK AND MATKHAU = @MATKHAU)
		BEGIN
			SET @ROLE = 'QTV';
		END
		ELSE
		BEGIN
			RAISERROR(N'Tải khoản hoặc mật khẩu không đúng.')
			ROLLBACK TRAN
			RETURN
		END

		SELECT @ROLE AS ROLE

	END TRY
	BEGIN CATCH
		ROLLBACK TRAN;
		DECLARE @errorMessage NVARCHAR(200) = ERROR_MESSAGE();
		THROW 51000, @errorMessage, 1;
		RETURN
	END CATCH
COMMIT TRAN

----------------------------------
--ALL02/ XEM DANH SÁCH DỊCH VỤ
GO
CREATE OR ALTER PROC SP_XEMDANHSACHDICHVU_ALL
AS
BEGIN TRAN
	BEGIN TRY
		SELECT * FROM LOAIDICHVU
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN;
		DECLARE @errorMessage NVARCHAR(200) = ERROR_MESSAGE();
		THROW 51000, @errorMessage, 1;
		RETURN
	END CATCH
COMMIT TRAN

----------------------------------
--ALL07/ XEM DANH SÁCH TẤT CẢ NHA SĨ CHƯA BỊ KHÓA TK
GO
CREATE OR ALTER PROC SP_XEMDANHSACHNHASI_ALL
AS
BEGIN TRAN
	BEGIN TRY
		SELECT NS.MANS, NS.HOTEN, NS.PHAI, NS.GIOITHIEU
		FROM NHASI NS
		WHERE NS._DAKHOA = 0
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN;
		DECLARE @errorMessage NVARCHAR(200) = ERROR_MESSAGE();
		THROW 51000, @errorMessage, 1;
		RETURN
	END CATCH
COMMIT TRAN

----------------------------------
--ALL02/ XEM THÔNG TIN TOÀN BỘ BẢNG CA
GO
CREATE OR ALTER PROC SP_XEMCA_ALL
AS
BEGIN TRAN
	BEGIN TRY
		SELECT * FROM CA
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN;
		DECLARE @errorMessage NVARCHAR(200) = ERROR_MESSAGE();
		THROW 51000, @errorMessage, 1;
		RETURN
	END CATCH
COMMIT TRAN