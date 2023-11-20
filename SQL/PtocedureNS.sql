use PKNHAKHOA 
GO
-- XEM CÁC CA ĐỦ 2 NG TRỰC TRỪ CA MÌNH ĐÃ ĐẶT (TỪ NGÀY HIỆN TẠI ĐẾN 30 NGÀY SAU)
CREATE PROCEDURE SP_XEMCADU2NGTRUC_NS
    @MANS VARCHAR(10)
AS
BEGIN TRAN
BEGIN TRY
BEGIN
    SET NOCOUNT ON;

    SELECT L1.MACA, L1.NGAY, C.GIOBATDAU, C.GIOKETTHUC
    FROM LICHRANH L1
        JOIN LICHRANH L2 ON L1.MACA = L2.MACA AND L1.NGAY = L2.NGAY AND L1.SOTT <> L2.SOTT
        JOIN CA C ON L1.MACA = C.MACA
    WHERE L1.MANS = @MANS
        AND L1.NGAY BETWEEN GETDATE() AND DATEADD(DAY, 30, GETDATE())
    GROUP BY L1.MACA, L1.NGAY, C.GIOBATDAU, C.GIOKETTHUC
    HAVING COUNT(DISTINCT L1.SOTT) = 2
END
END TRY 
BEGIN CATCH 
        ROLLBACK TRAN;
		DECLARE @errorMessage NVARCHAR(200) = ERROR_MESSAGE();
		THROW 51000, @errorMessage, 1
		RETURN
END CATCH
COMMIT TRAN
GO
-- TRUY VẤN CÁC LỊCH HẸN CỦA MÌNH (TỪ NGÀY HIỆN TẠI ĐẾN 30 NGÀY SAU)
CREATE PROCEDURE SP_XEMLICHHENNS_NS
    @MANS VARCHAR(10)
AS
BEGIN TRAN
BEGIN TRY
BEGIN
    SET NOCOUNT ON;

    SELECT
        LH.SOTT,
        LR.MACA,
        LR.NGAY,
        C.GIOBATDAU,
        C.GIOKETTHUC,
        KH.SODT AS SDT_KHACH,
        KH.HOTEN AS TEN_KHACH,
        LH.LYDOKHAM
    FROM
        LICHHEN LH
        JOIN
        LICHRANH LR ON LH.MANS = LR.MANS AND LH.SOTT = LR.SOTT
        JOIN
        CA C ON LR.MACA = C.MACA
        JOIN
        KHACHHANG KH ON LH.SODT = KH.SODT
    WHERE 
        LH.MANS = @MANS
        AND LR.NGAY BETWEEN GETDATE() AND DATEADD(DAY, 30, GETDATE());
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
-- TRUY VẤN CÁC LỊCH RẢNH CỦA MÌNH MÀ CHƯA ĐƯỢC ĐẶT LỊCH (TỪ NGÀY HIỆN TẠI ĐẾN 30 NGÀY SAU)
CREATE PROCEDURE SP_LICHRANHCHUADUOCDAT_NS
    @MANS VARCHAR(10)
AS
BEGIN TRAN 
BEGIN TRY 
BEGIN
    SET NOCOUNT ON;

    SELECT
        LR.MANS,
        LR.SOTT,
        LR.MACA,
        LR.NGAY,
        C.GIOBATDAU,
        C.GIOKETTHUC
    FROM
        LICHRANH LR
        JOIN
        CA C ON LR.MACA = C.MACA
    WHERE 
        LR.MANS = @MANS
        AND NOT EXISTS (
            SELECT 1
        FROM LICHHEN LHEN
        WHERE LHEN.MANS = LR.MANS AND LHEN.SOTT = LR.SOTT
        )
        AND LR.NGAY BETWEEN GETDATE() AND DATEADD(DAY, 30, GETDATE());
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
GO
-- ĐĂNG KÝ LỊCH RẢNH
CREATE OR ALTER PROCEDURE SP_DANGKYLR_NS
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
			  FROM LICHRANH
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
		FROM LICHRANH
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
GO

-- HỦY LỊCH RẢNH
CREATE PROCEDURE SP_HUYLR_NS
    @MANS VARCHAR(10),
    @SOTT INT
AS
BEGIN TRAN
BEGIN TRY
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (
        SELECT MANS, SOTT
    FROM LICHHEN
    WHERE MANS = @MANS
        AND SOTT = @SOTT
    )
    BEGIN
        DELETE FROM LICHRANH
        WHERE MANS = @MANS
            AND SOTT = @SOTT;
    END
    ELSE
    BEGIN
        ROLLBACK TRAN
        RAISERROR('Lịch rảnh đã được hẹn, không thể hủy.',16,1);
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
GO

-- TẠO BỆNH ÁN MỚI
CREATE PROCEDURE SP_TAOBENHAN_NS
    @SoDienThoai VARCHAR(10),
    @NgayKham DATE,
    @MaNS VARCHAR(10),
    @DanDo NVARCHAR(500)
AS
BEGIN TRAN      
BEGIN TRY
BEGIN
    IF @NGAY IS NULL
    BEGIN
        ROLLBACK TRAN
        RAISERROR(N'Ngày không thể null.',16,1);
        RETURN
    END
    DECLARE @Sott INT;
    SELECT @Sott = ISNULL(MAX(SOTT), 0) + 1
    FROM HOSOBENH
    WHERE SODT = @SoDienThoai;
    INSERT INTO HOSOBENH
        (SODT, SOTT, NGAYKHAM, MANS, DANDO)
    VALUES
        (@SoDienThoai, @Sott, @NgayKham, @MaNS, @DanDo);

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
-- THÊM CTDV VÀO BỆNH ÁN
CREATE PROCEDURE SP_THEMCTDV_NS
    @MaDV VARCHAR(10),
    @SOTT INT,
    @SoDienThoai VARCHAR(10),
    @SoLuongDV INT

AS
BEGIN TRAN 
BEGIN TRY
BEGIN
     IF @SoLuongDV IS NULL
    BEGIN
        ROLLBACK TRAN
        RAISERROR(N'Số lượng dịch vụ không thể null.',16,1);
        RETURN
    END
    INSERT INTO CHITIETDV
        (MADV, SOTT, SODT, SOLUONG)
    VALUES
        (@MaDV, @SOTT, @SoDienThoai, @SoLuongDV);

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
-- THÊM CTTHUOC VÀO BỆNH ÁN
CREATE OR ALTER PROCEDURE SP_THEMCTTHUOC_NS
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

	IF(EXISTS(SELECT SODT, SOTT, _DAXUATHOADON FROM HOSOBENH WHERE SODT = @SODT AND SOTT = @SOTT AND _DAXUATHOADON = 1))
    BEGIN
        RAISERROR(N'Lỗi: đã xuất hóa đơn, không thể thêm đơn thuốc được',16,1)
        ROLLBACK TRAN
        RETURN
    END

    ELSE 
        DECLARE @SLTON INT
        SELECT @SLTON = SLTON FROM LOAITHUOC WHERE MATHUOC = @MATHUOC
		
        IF(EXISTS(SELECT *
                  FROM LOAITHUOC LT
                  WHERE LT.MATHUOC = @MATHUOC AND @SOLUONG <= @SLTON AND LT.NGAYHETHAN < GETDATE()))
        BEGIN
            INSERT INTO CHITIETTHUOC(MATHUOC,SOTT,SODT,SOLUONG,THOIDIEMDUNG)
		    VALUES(@MATHUOC, @SOTT, @SODT, @SOLUONG, @THOIDIEMDUNG);
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
GO
