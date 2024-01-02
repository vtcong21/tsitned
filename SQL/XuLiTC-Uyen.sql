-- Lost update khi thêm nha sĩ đăng ký lịch trực
CREATE PROC SP_DANGKYLR_NS
    @MANS VARCHAR(10),
    @MACA VARCHAR(10),
    @NGAY DATE
AS
BEGIN TRAN
BEGIN TRY 
    SET NOCOUNT ON;
    IF @NGAY IS NULL
    BEGIN
        ROLLBACK TRAN
        RAISERROR(N'Ngày đăng ký không thể null.',16,1);
        RETURN
    END
	IF (@NGAY < GETDATE())
	BEGIN
		ROLLBACK TRAN
        RAISERROR(N'Ngày đăng ký không thể nhỏ hơn ngày hiện tại.',16,1);
        RETURN
	END
	-- Mỗi ca trong ngày chỉ được tối đa 2 nha sĩ được đăng ký. 
	IF(EXISTS(SELECT MACA, NGAY
			  FROM LICHRANH WITH(UPDLOCK, HOLDLOCK)
		      WHERE NGAY = @NGAY AND MACA = @MACA
			  GROUP BY MACA, NGAY
			  HAVING COUNT(MANS) > 1))
	BEGIN
        ROLLBACK TRAN
        RAISERROR(N'Lỗi: ca đã đủ 2 người đăng ký.',16,1);
        RETURN
    END

	ELSE
	BEGIN
		DECLARE @NextSOTT INT;
		SELECT @NextSOTT = ISNULL(MAX(SOTT), 0) + 1
		FROM LICHRANH WITH(UPDLOCK, HOLDLOCK)
		WHERE MANS = @MANS;

		INSERT INTO LICHRANH(MANS, MACA, NGAY, SOTT)
		VALUES(@MANS, @MACA, @NGAY, @NextSOTT);
	END
END TRY 
BEGIN CATCH 
        ROLLBACK TRAN;
		DECLARE @errorMessage NVARCHAR(200) = ERROR_MESSAGE();
		THROW 51000, @errorMessage, 1
		RETURN
END CATCH
COMMIT TRAN

-- Lost update khi nha sĩ đổi mật khẩu
GO
CREATE PROC SP_DOIMK_NS
	@MANS VARCHAR(100),
	@MATKHAUCU VARCHAR(100),
	@MATKHAUMOI VARCHAR(100)
AS
BEGIN TRAN
	BEGIN TRY
		-- Kiểm tra tồn tại tài khoản
		IF (NOT EXISTS(SELECT * FROM NHASI WHERE MANS = @MANS))
		BEGIN
			RAISERROR(N'Không tồn tại nha sĩ này', 16, 1);
			ROLLBACK TRAN
			RETURN
		END

		IF NOT EXISTS(SELECT 1 
                        FROM NHASI WITH(UPDLOCK)
                        WHERE MANS = @MANS 
                        AND MATKHAU = @MATKHAUCU)
		BEGIN 
			RAISERROR(N'Xác nhận mật khẩu sai', 16, 1);
			ROLLBACK TRAN
			RETURN
		END
		ELSE
		BEGIN
			UPDATE NHASI
			SET	MATKHAU = @MATKHAUMOI
			WHERE MANS = @MANS
		END
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN;
		DECLARE @errorMessage NVARCHAR(200) = ERROR_MESSAGE();
		THROW 51000, @errorMessage, 1;
		RETURN
	END CATCH
COMMIT TRAN

-- Unrepeatable Read khi Đăng nhập nhân viên
GO
CREATE OR ALTER PROC SP_DANGNHAP_ALL
	@MATK VARCHAR(100),
	@MATKHAU VARCHAR(20)
AS
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
BEGIN TRAN
	BEGIN TRY
		IF LEN(@MATK) > 10
		BEGIN
			RAISERROR(N'Tài khoản đăng nhập không hợp lệ.', 16, 1);
			ROLLBACK TRAN
			RETURN
		END 

		DECLARE @ROLE VARCHAR(10);
		DECLARE @_ISLOCK BIT;
		SET @ROLE = NULL;
		SET @_ISLOCK = NULL;

		--Kiểm tra tài khoản đăng nhập có hợp lệ (tk mà mk đều đúng)
		IF EXISTS (SELECT * FROM KHACHHANG WHERE SODT = @MATK AND MATKHAU = @MATKHAU)
		BEGIN
			
			SELECT @ROLE = 'KH', @_ISLOCK = _DAKHOA
			FROM KHACHHANG 
			WHERE SODT = @MATK AND MATKHAU = @MATKHAU;
		END
		ELSE IF EXISTS (SELECT * FROM NHASI WHERE MANS = @MATK AND MATKHAU = @MATKHAU)
		BEGIN
			SELECT @ROLE = 'NS', @_ISLOCK = _DAKHOA
			FROM NHASI 
			WHERE MANS = @MATK AND MATKHAU = @MATKHAU;
		END
		ELSE IF EXISTS (SELECT * FROM NHANVIEN WHERE MANV = @MATK AND MATKHAU = @MATKHAU)
		BEGIN
			SELECT @ROLE = 'NV', @_ISLOCK = _DAKHOA
			FROM NHANVIEN 
			WHERE MANV = @MATK AND MATKHAU = @MATKHAU;
		END
		ELSE IF EXISTS (SELECT * FROM QTV WHERE MAQTV = @MATK AND MATKHAU = @MATKHAU)
		BEGIN
			SET @ROLE = 'QTV';
			SET @_ISLOCK = 0;
		END
		ELSE
		BEGIN
			RAISERROR(N'Tài khoản hoặc mật khẩu không đúng.', 16, 1);
			ROLLBACK TRAN
			RETURN
		END

		IF (@_ISLOCK = 1)
		BEGIN
			RAISERROR(N'Tài khoản đã bị khóa.', 16, 1);
			ROLLBACK TRAN
			RETURN
		END
		
		IF @ROLE = 'KH'
		BEGIN
			SELECT 'KH' AS ROLE, SODT, HOTEN, PHAI, NGAYSINH, DIACHI
			FROM KHACHHANG
			WHERE SODT = @MATK;
		END
		ELSE IF @ROLE = 'NS'
		BEGIN
			SELECT 'NS' AS ROLE, MANS, HOTEN, PHAI, GIOITHIEU
			FROM NHASI
			WHERE MANS = @MATK;
		END
		ELSE IF @ROLE = 'NV'
		BEGIN
			SELECT 'NV' AS ROLE, MANV, HOTEN, PHAI, VITRICV
			FROM NHANVIEN
			WHERE MANV = @MATK;
		END
		ELSE IF @ROLE = 'QTV'
		BEGIN
			SELECT 'QTV' AS ROLE, MAQTV, HOTEN, PHAI
			FROM QTV
			WHERE MAQTV = @MATK;
		END

	END TRY
	BEGIN CATCH
		ROLLBACK TRAN;
		DECLARE @errorMessage NVARCHAR(200) = ERROR_MESSAGE();
		THROW 51000, @errorMessage, 1;
		RETURN
	END CATCH
COMMIT TRAN

GO
CREATE PROC SP_DOIMK_NV
	@MANV VARCHAR(100),
	@MATKHAUCU VARCHAR(100),
	@MATKHAUMOI VARCHAR(100)
AS
BEGIN TRAN
	BEGIN TRY
		-- Kiểm tra tồn tại tài khoản
		IF (NOT EXISTS(SELECT * FROM NHANVIEN WHERE MANV = @MANV))
		BEGIN
			RAISERROR(N'Không tồn tại nhân viên này', 16, 1);
			ROLLBACK TRAN
			RETURN
		END

		IF NOT EXISTS(SELECT 1 
                        FROM NHANVIEN WITH(UPDLOCK)
                        WHERE MANV = @MANV 
                        AND MATKHAU = @MATKHAUCU)
		BEGIN 
			RAISERROR(N'Xác nhận mật khẩu sai', 16, 1);
			ROLLBACK TRAN
			RETURN
		END
		ELSE
		BEGIN
			UPDATE NHANVIEN
			SET	MATKHAU = @MATKHAUMOI
			WHERE MANV = @MANV
		END
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN;
		DECLARE @errorMessage NVARCHAR(200) = ERROR_MESSAGE();
		THROW 51000, @errorMessage, 1;
		RETURN
	END CATCH
COMMIT TRAN

-- Phantom Read khi Nhân viên tạo và in hóa đơn và Nha sĩ thêm dịch vụ vào bệnh án
GO
CREATE PROC SP_TAOHOADON_NV
	@SODT VARCHAR(100),
	@SOTT INT,
	@MANV VARCHAR(100)
AS
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
BEGIN TRAN
	BEGIN TRY
		IF EXISTS(SELECT 1 
                    FROM HOSOBENH 
                    WHERE SODT = @SODT 
                    AND SOTT = @SODT)
		BEGIN
			RAISERROR(N'Hồ sơ bệnh không tồn tại', 16, 1);
			ROLLBACK TRAN
			RETURN
		END

		IF EXISTS(SELECT 1 
                    FROM HOSOBENH WITH(UPDLOCK)
                    WHERE SODT = @SODT 
                    AND SOTT = @SODT 
                    AND _DAXUATHOADON = 1)
		BEGIN
			RAISERROR(N'Hồ sơ bệnh đã được xuất hóa đơn', 16, 1);
			ROLLBACK TRAN
			RETURN
		END

		IF NOT EXISTS(SELECT 1 FROM CHITIETDV WHERE SODT = @SODT AND SOTT = @SOTT)
		BEGIN
			RAISERROR(N'Hồ sơ bệnh chưa được thêm dịch vụ vào', 16, 1);
			ROLLBACK TRAN
			RETURN
		END
		ELSE

		BEGIN
			DECLARE @TONGCHIPHI FLOAT;
			DECLARE @TIENDV FLOAT
			DECLARE @TIENTHUOC FLOAT;

			SELECT @TIENTHUOC = ISNULL(SUM(DONGIALUCTHEM * SOLUONG), 0)
			FROM CHITIETTHUOC CTT
			WHERE CTT.SODT = @SODT AND CTT.SOTT = @SOTT;

			SELECT @TIENDV = ISNULL(SUM(DONGIALUCTHEM * SOLUONG), 0)
			FROM CHITIETDV CTDV
			WHERE CTDV.SODT = @SODT AND CTDV.SOTT = @SOTT;
			
			SET @TONGCHIPHI = @TIENTHUOC + @TIENDV

			INSERT INTO HOADON(SODT, SOTT, NGAYXUAT, TONGCHIPHI, _DATHANHTOAN, MANV)
			VALUES(@SODT, @SOTT, GETDATE(), @TONGCHIPHI, 0, @MANV)

			UPDATE HOSOBENH 
			SET _DAXUATHOADON = 1
			WHERE SOTT = @SOTT AND SODT = @SODT

			SELECT KH.HOTEN HOTENKH, HD.SODT SODT, HD.SOTT SOTTHD, NGAYXUAT, TONGCHIPHI, NV.MANV MANV, NV.HOTEN HOTENNV, _DATHANHTOAN DATHANHTOAN, CTDV.MADV, TENDV, CTDV.SOLUONG SLDV, CTDV.DONGIALUCTHEM DONGIADV, CTT.MATHUOC, TENTHUOC, CTT.SOLUONG SLTHUOC, DONVITINH, CTT.DONGIALUCTHEM DONGIATHUOC
			FROM HOADON HD
			JOIN KHACHHANG KH ON HD.SODT = KH.SODT
			JOIN NHANVIEN NV ON NV.MANV = HD.MANV
			JOIN CHITIETDV CTDV ON CTDV.SODT = HD.SODT AND CTDV.SOTT = HD.SOTT
			JOIN LOAIDICHVU LDV ON LDV.MADV = CTDV.MADV
			LEFT JOIN CHITIETTHUOC CTT ON CTT.SODT = HD.SODT AND CTT.SOTT = HD.SOTT
			LEFT JOIN LOAITHUOC	LT ON LT.MATHUOC = CTT.MATHUOC
			WHERE HD.SOTT = @SOTT AND HD.SODT = @SODT
		END
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN;
		DECLARE @errorMessage NVARCHAR(200) = ERROR_MESSAGE();
		THROW 51000, @errorMessage, 1;
		RETURN
	END CATCH
COMMIT TRAN

GO
CREATE PROC SP_THEMCTTHUOC_NS
    @MATHUOC VARCHAR(10),
    @SOTT INT,
    @SODT VARCHAR(10),
    @SOLUONG INT,
    @THOIDIEMDUNG NVARCHAR(200)
AS
BEGIN TRAN
BEGIN TRY
BEGIN
    IF @SOLUONG IS NULL OR @THOIDIEMDUNG IS NULL
    BEGIN
        ROLLBACK TRAN
        RAISERROR(N'Số lượng và thời điểm dùng không thể null.',16,1);
        RETURN
    END

	IF (NOT EXISTS(SELECT * 
				   FROM HOSOBENH 
				   WHERE SOTT = @SOTT AND SODT = @SODT))
	BEGIN
        ROLLBACK TRAN
        RAISERROR(N'Không tồn tại hồ sơ bệnh.',16,1);
        RETURN
    END

	IF(NOT EXISTS(SELECT * FROM LOAITHUOC WHERE MATHUOC = @MATHUOC))
    BEGIN
        RAISERROR(N'Thuốc này không tồn tại trong kho',16,1)
        ROLLBACK TRAN
        RETURN
    END

	IF(EXISTS(SELECT SODT, SOTT, _DAXUATHOADON 
                FROM HOSOBENH WITH(UPDLOCK, HOLDLOCK)
                WHERE SODT = @SODT 
                AND SOTT = @SOTT 
                AND _DAXUATHOADON = 1))
    BEGIN
        RAISERROR(N'Lỗi: đã xuất hóa đơn, không thể thêm đơn thuốc được',16,1)
        ROLLBACK TRAN
        RETURN
    END

    ELSE 
        DECLARE @SLTON INT
        SELECT @SLTON = SLTON FROM LOAITHUOC WHERE MATHUOC = @MATHUOC
        
        DECLARE @DONGIALUCTHEM FLOAT
        SELECT @DONGIALUCTHEM = DONGIA FROM LOAITHUOC WHERE MATHUOC = @MATHUOC
		
        IF(EXISTS(SELECT *
                  FROM LOAITHUOC LT
                  WHERE LT.MATHUOC = @MATHUOC AND @SOLUONG <= @SLTON AND LT.NGAYHETHAN > GETDATE()))
        BEGIN
            INSERT INTO CHITIETTHUOC(MATHUOC,SOTT,SODT,SOLUONG,THOIDIEMDUNG, DONGIALUCTHEM)
		    VALUES(@MATHUOC, @SOTT, @SODT, @SOLUONG, @THOIDIEMDUNG, @DONGIALUCTHEM);
		    UPDATE LOAITHUOC SET SLTON = @SLTON - @SOLUONG WHERE MATHUOC = @MATHUOC;
        END
        ELSE
        BEGIN
            RAISERROR(N'Lỗi: không đủ số lượng thuốc tồn kho để bán',16,1)
            ROLLBACK TRAN
            RETURN
        END
END;
END TRY 
BEGIN CATCH 
        ROLLBACK TRAN;
		DECLARE @errorMessage NVARCHAR(200) = ERROR_MESSAGE();
		THROW 51000, @errorMessage, 1
		RETURN
END CATCH
COMMIT TRAN

-- Dirty read khi quản trị viên cập nhật thông tin dịch vụ và xem danh sách tất cả dịch vụ
GO
CREATE PROC SP_CAPNHATDICHVU_QTV
    @MADV VARCHAR(10),
    @TENDV NVARCHAR(100) = NULL,
    @CHITIET NVARCHAR(500) = NULL,
    @DONGIA INT = NULL
AS
BEGIN TRAN
BEGIN TRY
BEGIN
    IF @DONGIA <= 0
    BEGIN
        RAISERROR(N'đơn giá không được nhỏ hơn hoặc bằng 0', 16, 1)
        ROLLBACK TRAN
        RETURN
    END
    IF @TENDV IS NOT NULL OR @CHITIET IS NOT NULL OR @DONGIA IS NOT NULL
    BEGIN
        UPDATE LOAIDICHVU
        SET TENDV = ISNULL(@TENDV, TENDV),
            MOTA = ISNULL(@CHITIET, MOTA),
            DONGIA = ISNULL(@DONGIA, DONGIA)
        WHERE MADV = @MADV;
    END
    ELSE
    BEGIN
        RAISERROR(N'Không có thông tin nào được cập nhật.',16,1);
    END
END;
END TRY 
BEGIN CATCH 
        ROLLBACK TRAN;
		DECLARE @errorMessage NVARCHAR(200) = ERROR_MESSAGE();
		THROW 51000, @errorMessage, 1
		RETURN
END CATCH
COMMIT TRAN

GO
CREATE PROC SP_XEMDANHSACHDICHVU_ALL
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