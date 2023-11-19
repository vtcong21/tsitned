USE PKNHAKHOA
GO

-- THÊM LOẠI THUỐC MỚI
CREATE PROCEDURE SP_THEMLOAITHUOC_QTV
    @TENTHUOC NVARCHAR(100),
    @DONVITINH NVARCHAR(50),
    @CHIDINH NVARCHAR(500),
    @SLNHAP INT,
    @NGAYHETHAN DATE,
    @DONGIA FLOAT
AS
BEGIN TRAN
BEGIN TRY 
BEGIN
    IF @SLNHAP < 1 OR @DONGIA < 1
    BEGIN
        RAISERROR(N'Số lượng nhập và đơn giá không được nhỏ hơn hoặc bằng 0', 16, 1)
        ROLLBACK TRAN
        RETURN
    END

    DECLARE @NewMATHUOC VARCHAR(10);

    SELECT @NewMATHUOC = COALESCE(MAX(MATHUOC), 'MT01')
    FROM LOAITHUOC;
    SET @NewMATHUOC = 'MT' + RIGHT('00' + CAST(CAST(RIGHT(@NewMATHUOC, 2) AS INT) + 1 AS VARCHAR(2)), 2);
    INSERT INTO LOAITHUOC
        (MATHUOC, TENTHUOC, DONVITINH, CHIDINH, SLTON, SLNHAP, SLDAHUY, NGAYHETHAN, DONGIA)
    VALUES
        (@NewMATHUOC, @TENTHUOC, @DONVITINH, @CHIDINH, @SLNHAP, @SLNHAP, 0, @NGAYHETHAN, @DONGIA);
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

-- HỦY LOẠI THUỐC
CREATE PROCEDURE SP_HUYTHUOC_QTV
    @MATHUOC VARCHAR(10)
AS
BEGIN TRAN
BEGIN TRY 
BEGIN
    DECLARE @NGAYHETHAN DATE;

    SELECT @NGAYHETHAN = NGAYHETHAN
    FROM LOAITHUOC
    WHERE MATHUOC = @MATHUOC;

    IF @NGAYHETHAN < GETDATE()
    BEGIN

        UPDATE LOAITHUOC
        SET SLDAHUY = SLDAHUY + SLTON, SLTON = 0
        WHERE MATHUOC = @MATHUOC;
    END
    ELSE
    BEGIN
        RAISERROR(N'Không thể hủy thuốc vì chưa hết hạn.',16,1);
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
-- CẬP NHẬT THUỐC
CREATE PROCEDURE SP_CAPNHATLOAITHUOC_QTV
    @MATHUOC VARCHAR(10),
    @TENTHUOC NVARCHAR(50) = NULL,
    @CHIDINH NVARCHAR(500) = NULL,
    @DONGIA FLOAT = NULL
AS
BEGIN TRAN
BEGIN TRY 
BEGIN
    IF  @DONGIA <= 0
    BEGIN
        RAISERROR(N'Đơn giá không được nhỏ hơn hoặc bằng 0', 16, 1)
        ROLLBACK TRAN
        RETURN
    END

    IF @TENTHUOC IS NOT NULL OR @CHIDINH IS NOT NULL OR @DONGIA IS NOT NULL
    BEGIN
        UPDATE LOAITHUOC
        SET 
            TENTHUOC = ISNULL(@TENTHUOC,TENTHUOC),
            CHIDINH = ISNULL(@CHIDINH, CHIDINH),
            DONGIA = ISNULL(@DONGIA, DONGIA)
        WHERE MATHUOC = @MATHUOC;
    END
    ELSE
    BEGIN
        RAISERROR(N'Không có thông tin mới để cập nhật.',16,1);
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

-- NHẬP THUỐC
CREATE PROCEDURE SP_NHAPTHEMTHUOC_QTV
    @MATHUOC VARCHAR(10),
    @SOLUONGNHAP INT,
    @NGAYHETHAN DATE
AS
BEGIN TRAN
BEGIN TRY 
BEGIN
    SET NOCOUNT ON;
    IF @SOLUONGNHAP < 1
    BEGIN
        RAISERROR(N'Số lượng nhập không được nhỏ hơn hoặc bằng 0', 16, 1)
        ROLLBACK TRAN
        RETURN
    END


    DECLARE @SLTON_OLD INT, @SLTON_NEW INT, @SLNHAP_OLD INT, @SLNHAP_NEW INT, @NGAYHETHAN_OLD DATE;

    SELECT @SLTON_OLD = ISNULL(SLTON, 0), @NGAYHETHAN_OLD = NGAYHETHAN, @SLNHAP_OLD = SLNHAP
    FROM LOAITHUOC
    WHERE MATHUOC = @MATHUOC;


    IF @SLTON_OLD = 0
    BEGIN

        SET @SLTON_NEW = @SOLUONGNHAP;
        SET @SLNHAP_NEW = @SLNHAP_OLD + @SOLUONGNHAP;

        UPDATE LOAITHUOC
        SET SLTON = @SLTON_NEW, SLNHAP = @SLNHAP_NEW, NGAYHETHAN = @NGAYHETHAN
        WHERE MATHUOC = @MATHUOC;

    END
    ELSE IF @NGAYHETHAN_OLD <= GETDATE() 
    BEGIN
        SET @SLTON_NEW = @SOLUONGNHAP;
        SET @SLNHAP_NEW = @SLNHAP_OLD + @SOLUONGNHAP;

        UPDATE LOAITHUOC
        SET SLTON = @SLTON_NEW, SLNHAP = @SLNHAP_NEW, NGAYHETHAN = @NGAYHETHAN, SLDAHUY = SLDAHUY + @SLTON_OLD
        WHERE MATHUOC = @MATHUOC;
    END
    ELSE
    BEGIN
        RAISERROR(N'Ngày hết hạn không hợp lệ hoặc thuốc đã hết hạn.',16,1);
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

-- THÊM DV
CREATE PROCEDURE SP_THEMDICHVU_QTV
    @TENDV NVARCHAR(100),
    @CHITIET NVARCHAR(500),
    @DONGIA FLOAT
AS
BEGIN TRAN
BEGIN TRY
BEGIN
    SET NOCOUNT ON;
    IF @DONGIA <= 0
    BEGIN
        RAISERROR(N'đơn giá không được nhỏ hơn hoặc bằng 0', 16, 1)
        ROLLBACK TRAN
        RETURN
    END

    DECLARE @NewMADV VARCHAR(10);

    SELECT @NewMADV = COALESCE(MAX(MADV), 'DV01')
    FROM LOAIDICHVU;
    SET @NewMADV = 'DV' + RIGHT('00' + CAST(CAST(RIGHT(@NewMADV, 2) AS INT) + 1 AS VARCHAR(2)), 2);

    INSERT INTO LOAIDICHVU
        (MADV, TENDV, MOTA, DONGIA)
    VALUES
        (@NewMADV, @TENDV, @CHITIET, @DONGIA);
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

-- CẬP NHẬT DV
CREATE PROCEDURE SP_CAPNHATDICHVU_QTV
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
-- XEM DS NHÂN VIÊN
CREATE PROCEDURE SP_XEMDANHSACHNHANVIEN
AS
BEGIN TRAN
BEGIN TRY
BEGIN
    SET NOCOUNT ON;

    SELECT MANV, HOTEN, PHAI, VITRICV, _DAKHOA
    FROM NHANVIEN;
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


-------------------------
--QTV08/ TẠO NHÂN VIÊN MỚI
GO
CREATE OR ALTER PROC SP_CREATENV_QTV
    @HOTEN NVARCHAR(50),
    @PHAI NVARCHAR(100),
    @VITRICV NVARCHAR(200)
AS
BEGIN TRAN
BEGIN TRY
		BEGIN
    DECLARE @MANV NVARCHAR(10);
    -- Lấy giá trị MANV lớn nhất hiện tại
    SELECT TOP 1
        @MANV = 'NV' + RIGHT('0000' + CAST(CAST(SUBSTRING(MANV, 3, LEN(MANV) - 2) AS INT) + 1 AS NVARCHAR(5)), 4)
    FROM NHANVIEN
    ORDER BY CAST(SUBSTRING(MANV, 3, LEN(MANV) - 2) AS INT) DESC;

    INSERT INTO NHANVIEN
        (MANV, HOTEN, PHAI, VITRICV, MATKHAU, _DAKHOA)
    VALUES(@MANV, @HOTEN, @PHAI, @VITRICV, @MANV, 0)
END
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN;
		DECLARE @errorMessage NVARCHAR(200) = ERROR_MESSAGE();
		THROW 51000, @errorMessage, 1;
		RETURN
	END CATCH
COMMIT TRAN

--------------------------
--QTV09/ CẬP NHÂT THÔNG TIN NHÂN VIÊN
GO
CREATE OR ALTER PROC SP_UPDATENV_QTV
    @MANV VARCHAR(100),
    @VITRICV NVARCHAR(200)
AS
BEGIN TRAN
    BEGIN TRY
		IF (NOT EXISTS(SELECT *
            FROM NHANVIEN
            WHERE MANV = @MANV))
		BEGIN
            RAISERROR(N'Không tồn tại nhân viên trên', 16, 1);
            ROLLBACK TRAN
            RETURN
        END
		ELSE
		BEGIN
            UPDATE NHANVIEN
			SET VITRICV = @VITRICV
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
-------------
--QTV10/ KHÓA TÀI KHOẢN NHÂN VIÊN
GO
CREATE OR ALTER PROC SP_BLOCKNV_QTV
    @MANV VARCHAR(100)
AS
BEGIN TRAN
    BEGIN TRY
		IF (NOT EXISTS(SELECT *
            FROM NHANVIEN
            WHERE MANV = @MANV))
		BEGIN
            RAISERROR(N'Không tồn tại nhân viên trên', 16, 1);
            ROLLBACK TRAN
            RETURN
        END
		ELSE
		BEGIN
            UPDATE NHANVIEN
			SET _DAKHOA = 1
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
--------------------------
--QTV11/ MỞ KHÓA TK NHÂN VIÊN
GO
CREATE OR ALTER PROC SP_UNBLOCKNV_QTV
    @MANV VARCHAR(100)
AS
BEGIN TRAN
BEGIN TRY
		IF (NOT EXISTS(SELECT *
            FROM NHANVIEN
            WHERE MANV = @MANV))
		BEGIN
            RAISERROR(N'Không tồn tại nhân viên trên', 16, 1);
            ROLLBACK TRAN
            RETURN
        END
		ELSE
		BEGIN
            UPDATE NHANVIEN
			SET _DAKHOA = 0
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
-----------
--QTV12/ XEM DANH SÁCH NHA SĨ
GO
CREATE OR ALTER PROC SP_GETALLNS_QTV
AS
BEGIN TRAN
    BEGIN TRY
		SELECT MANS, HOTEN, PHAI, GIOITHIEU, _DAKHOA
        FROM NHASI
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN;
		DECLARE @errorMessage NVARCHAR(200) = ERROR_MESSAGE();
		THROW 51000, @errorMessage, 1;
		RETURN
	END CATCH
COMMIT TRAN
--------------
-----------
--QTV13/ TẠO NHA SĨ MỚI
GO
CREATE OR ALTER PROC SP_CREATENS_QTV
    @HOTEN NVARCHAR(50),
    @PHAI NVARCHAR(100),
    @GIOITHIEU NVARCHAR(500)
AS
BEGIN TRAN
    BEGIN TRY
        DECLARE @MANS NVARCHAR(10);

        -- Lấy giá trị MANS lớn nhất hiện tại
        SELECT TOP 1
            @MANS = 'NS' + RIGHT('0000' + CAST(CAST(SUBSTRING(MANS, 3, LEN(MANS) - 2) AS INT) + 1 AS NVARCHAR(5)), 4)
        FROM NHASI
        ORDER BY CAST(SUBSTRING(MANS, 3, LEN(MANS) - 2) AS INT) DESC;

        INSERT INTO NHASI
            (MANS, HOTEN, PHAI, GIOITHIEU, MATKHAU, _DAKHOA)
        VALUES(@MANS, @HOTEN, @PHAI, @GIOITHIEU, @MANS, 0)

	END TRY
	BEGIN CATCH
		ROLLBACK TRAN;
		DECLARE @errorMessage NVARCHAR(200) = ERROR_MESSAGE();
		THROW 51000, @errorMessage, 1;
		RETURN
	END CATCH
COMMIT TRAN


--QTV14/ CẬP NHẬT THÔNG TIN NHA SĨ
GO
CREATE OR ALTER PROC SP_UPDATENV_QTV
    @MANS VARCHAR(100),
    @GIOITHIEU NVARCHAR(200)
AS
BEGIN TRAN
    BEGIN TRY
		IF (NOT EXISTS(SELECT *
            FROM NHASI
            WHERE MANS = @MANS))
		BEGIN
            RAISERROR(N'Không tồn tại nha sĩ trên', 16, 1);
            ROLLBACK TRAN
            RETURN
        END
		ELSE
		BEGIN
            UPDATE NHASI
			SET GIOITHIEU = @GIOITHIEU
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


--15. Khóa tài khoản nha sĩ
GO
CREATE OR ALTER PROC SP_KHOA_TAI_KHOAN_NHA_SI
    @MA_NS VARCHAR(10)
AS

BEGIN TRAN
BEGIN TRY
        IF EXISTS (SELECT 1
                    FROM NHASI
                    WHERE MANS = @MA_NS)
        BEGIN
            UPDATE NHASI
            SET _DAKHOA = 1
            WHERE MANS = @MA_NS
        END
        ELSE
        BEGIN
            RAISERROR(N'Không tồn tại mã nha sĩ này', 16, 1)
            ROLLBACK TRAN
            RETURN
        END
    END TRY

    BEGIN CATCH
        ROLLBACK TRAN
        DECLARE @errorMessage NVARCHAR(200) = ERROR_MESSAGE();
		THROW 51000, @errorMessage, 1;
		RETURN
    END CATCH
COMMIT TRAN





--16. Mở tài khoản nha sĩ
GO
CREATE OR ALTER PROC SP_MO_TAI_KHOAN_NHA_SI
    @MA_NS VARCHAR(10)
AS

BEGIN TRAN
    BEGIN TRY
        IF EXISTS (SELECT 1
                    FROM NHASI
                    WHERE MANS = @MA_NS)
        BEGIN
            UPDATE NHASI
            SET _DAKHOA = 0
            WHERE MANS = @MA_NS
        END
        ELSE
        BEGIN
            RAISERROR(N'Không tồn tại mã nha sĩ này', 16, 1)
            ROLLBACK TRAN
            RETURN
        END
    END TRY
    BEGIN CATCH
        ROLLBACK TRAN
        DECLARE @errorMessage NVARCHAR(200) = ERROR_MESSAGE();
		THROW 51000, @errorMessage, 1;
		RETURN
    END CATCH
COMMIT TRAN

--17. Xem danh sách QTV
-- XEM HET TAT CA CAC THUOC TINH CUA QTV TRU MAT KHAU

GO
CREATE OR ALTER PROC SP_XEM_DANH_SACH_QTV
AS
BEGIN TRAN
    BEGIN TRY
        IF EXISTS (SELECT 1
                    FROM QTV)
        BEGIN
            SELECT QTV.MAQTV, QTV.HOTEN, QTV.PHAI
            FROM QTV
        END
        ELSE
        BEGIN
            RAISERROR(N'Không tồn tại quản trị viên nào', 16, 1)
            ROLLBACK TRAN
            RETURN
        END
    END TRY

    BEGIN CATCH
        ROLLBACK TRAN
        DECLARE @errorMessage NVARCHAR(200) = ERROR_MESSAGE();
		THROW 51000, @errorMessage, 1;
		RETURN
    END CATCH
COMMIT TRAN


--18. Tạo Quản trị viên mới
GO
CREATE OR ALTER PROC SP_TAO_QTV_MOI

    @HOTEN VARCHAR(50),
    @PHAI NVARCHAR(5)

AS
BEGIN TRAN
    BEGIN TRY
        IF EXISTS (SELECT 1
                    FROM QTV)
        BEGIN
            INSERT INTO QTV (HOTEN,PHAI)
            VALUES(@HOTEN, @PHAI)
        END
        ELSE
        BEGIN
            RAISERROR(N'Không thể tạo quản trị viên mới', 16, 1)
            ROLLBACK TRAN
            RETURN
        END
    END TRY

    BEGIN CATCH
        ROLLBACK TRAN
        DECLARE @errorMessage NVARCHAR(200) = ERROR_MESSAGE();
		THROW 51000, @errorMessage, 1;
		RETURN
    END CATCH
COMMIT TRAN
--19. Xem danh sách khách hàng 
GO
CREATE OR ALTER PROC SP_XEM_DANH_SACH_KHACH_HANG

AS
BEGIN TRAN
    BEGIN TRY
        IF EXISTS (SELECT 1
                    FROM KHACHHANG)
        BEGIN
            SELECT KH.SODT, KH.HOTEN, KH.PHAI, KH.NGAYSINH, KH.DIACHI, KH._DAKHOA
            FROM KHACHHANG KH
        END
        ELSE
        BEGIN
            RAISERROR(N'Không tìm thấy danh sách khách hàng nào', 16, 1)
            ROLLBACK TRAN
            RETURN
        END
    END TRY

    BEGIN CATCH
        ROLLBACK TRAN
        DECLARE @errorMessage NVARCHAR(200) = ERROR_MESSAGE();
		THROW 51000, @errorMessage, 1;
		RETURN
    END CATCH
COMMIT TRAN

--20. Khóa Tài khoản khách hàng
GO
CREATE OR ALTER PROC SP_KHOA_TAI_KHOAN_KHACH_HANG
    @SODT VARCHAR(20)
AS
BEGIN TRAN
    BEGIN TRY
        IF EXISTS (SELECT 1
                    FROM KHACHHANG
                    WHERE SODT = @SODT)
        BEGIN
            UPDATE KHACHHANG
            SET _DAKHOA = 1
            WHERE SODT = @SODT
        END
        ELSE
        BEGIN
            RAISERROR(N'Không tìm thấy khách hàng nào', 16, 1)
            ROLLBACK TRAN
            RETURN
        END
    END TRY

    BEGIN CATCH
        ROLLBACK TRAN
        DECLARE @errorMessage NVARCHAR(200) = ERROR_MESSAGE();
		THROW 51000, @errorMessage, 1;
		RETURN
    END CATCH
COMMIT TRAN


--21. Mở tài khoản khách hàng
GO
CREATE OR ALTER PROC SP_MO_TAI_KHOAN_KHACH_HANG
    @SODT VARCHAR(20)
AS
BEGIN TRAN
    BEGIN TRY
        IF EXISTS (SELECT 1
                    FROM KHACHHANG
                    WHERE SODT = @SODT)
        BEGIN
            UPDATE KHACHHANG
            SET _DAKHOA = 0
            WHERE SODT = @SODT
        END
        ELSE
        BEGIN
            RAISERROR(N'Không thẻ mở tài khoản khách hàng này', 16, 1)
            ROLLBACK TRAN
            RETURN
        END
    END TRY

    BEGIN CATCH
        ROLLBACK TRAN
        DECLARE @errorMessage NVARCHAR(200) = ERROR_MESSAGE();
		THROW 51000, @errorMessage, 1;
		RETURN
    END CATCH
COMMIT TRAN
