USE PKNHAKHOA 
GO
-- CHẠY TỪNG CÁI NHÉ
EXEC SP_XEMCADU2NGTRUC_NS @MANS = 'NS0001';
EXEC SP_XEMLICHHENNS_NS @MANS = 'NS0001';
EXEC SP_LICHRANHCHUADUOCDAT_NS @MANS = 'NS0001';
EXEC SP_DANGKYLR_NS @MANS = 'NS0001', @MACA = 'CA001', @NGAY = '2023-11-14';
EXEC SP_HUYLR_NS @MANS = 'NS0001', @SOTT = 5;
EXEC SP_XEMBENHAN_NS @SoDienThoai = '0371234567';
EXEC SP_TAOBENHAN_NS 
    @SoDienThoai = '0371234567', 
    @NgayKham = '2023-11-14', 
    @MaNS = 'NS0001', 
    @DanDo = 'YourDanDO', 
    @MaDV = 'DV01', 
    @SoLuongDV = 1, 
    @MaThuoc = 'MT01', 
    @SoLuongThuoc = 1, 
    @ThoiDiemDung = '2023-11-14';