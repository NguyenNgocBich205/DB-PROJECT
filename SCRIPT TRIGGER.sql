--Trigger cập nhật hàng tồn kho khi nhập hàng
CREATE TRIGGER TR_CAPNHAT_TONKHO
ON CHI_TIET_NHAP_HANG
AFTER INSERT
AS
BEGIN
	UPDATE CHI_TIET_TON_KHO 
	SET 	SoLuongTon  = SoLuongTon + I.SoLuongNhap
	FROM CHI_TIET_TON_KHO CTTK
	INNER JOIN INSERTED I ON CTTK.MaSP = I.MaSP
END

--Trigger cập nhật số lượng tồn kho khi khách đặt hàng thành công
CREATE TRIGGER TR_CAPNHATTONKHO_THEODON
ON CHI_TIET_DON_HANG
AFTER INSERT
AS
BEGIN
 	UPDATE CTTK
    	SET CTTK.SoLuongTon = CTTK.SoLuongTon - I.SoLuong
    	FROM CHI_TIET_TON_KHO CTTK
    	INNER JOIN inserted I ON CTTK.MaSP = I.MaSP
END;

--Trigger thông báo khi số lượng sản phẩm sắp hết hàng (set dưới 10 thì tbao)
CREATE TRIGGER TR_TB_SAPHETHANG
ON CHI_TIET_TON_KHO
AFTER UPDATE
AS
BEGIN
        IF EXISTS (
        SELECT 1
        FROM inserted I
        WHERE I.SoLuongTon < 10
    		)
    BEGIN
        	PRINT (N'CẢNH BÁO: Sản phẩm sắp hết hàng!');
    END
END;

--Trigger kiểm tra số lượng tồn kho khi đặt hàng (đảm bảo số lượng khách đặt không vượt quá số lượng tồn kho)
CREATE TRIGGER TR_KIEMTRATONKHO
ON CHI_TIET_DON_HANG
INSTEAD OF INSERT
AS
BEGIN
         IF EXISTS (
        SELECT 1
        FROM inserted I
        INNER JOIN CHI_TIET_TON_KHO CTTK ON I.MaSP = CTTK.MaSP
        WHERE I.SoLuong > CTTK.SoLuongTon
    )
    BEGIN
             	PRINT (N'Số lượng tồn kho không đủ để đặt hàng!');
        	ROLLBACK;
        	RETURN;
    END;
    INSERT INTO CHI_TIET_DON_HANG (MaDH, MaSP, SoLuong, DonGia)
    SELECT MaDH, MaSP, SoLuong, DonGia FROM inserted;
END;

--DON_HANG: Trigger hoàn lại số lượng hàng khi bị hủy đơn
CREATE TRIGGER TR_HOANLAI_DONHANG
ON DON_HANG
AFTER DELETE
AS
BEGIN
    UPDATE CHI_TIET_TON_KHO
    SET SoLuongTon = SoLuongTon + CTDH.SoLuong
    FROM CHI_TIET_TON_KHO CTTK
    INNER JOIN CHI_TIET_DON_HANG CTDH ON CTTK.MaSP = CTDH.MaSP
    INNER JOIN deleted D ON D.MaDH = CTDH.MaDH;
END;


--DANH_GIA_SP: Trigger ghi nhận đánh giá chỉ khi đơn hoàn thành
CREATE TRIGGER TR_DANHGIA 
ON DANH_GIA_SP
AFTER INSERT, UPDATE
AS
BEGIN
    DECLARE @MaSP CHAR(10), @MaDH CHAR(10), @TrangThaiGiao NVARCHAR(20)
    SELECT @MaSP = I.MaSP, @MaDH = I.MaDH 
    FROM INSERTED I
    SELECT @TrangThaiGiao = TrangThaiGiao 
    FROM THONG_TIN_GIAO_HANG 
    WHERE MaDH = @MaDH
    IF @TrangThaiGiao <> N'Giao hàng thành công'
    BEGIN
        RAISERROR(N'Chỉ có thể đánh giá sản phẩm khi đơn hàng đã được giao.', 16, 1)
        ROLLBACK TRANSACTION
    END
END

--SAN_PHAM: Trigger ngày xóa sản phẩm phải sau ngày tạo
CREATE TRIGGER TR_NGAYXOA ON SAN_PHAM
AFTER INSERT, UPDATE
  AS
  BEGIN
   DECLARE @ngaytaosp DATE, @ngayxoasp DATE
   SELECT @ngaytaosp = NgayTaoSP, @ngayxoasp = NgayXoaSP 
   FROM INSERTED
   IF @NgayXoaSP IS NOT NULL AND @NgayTaoSP > @NgayXoaSP
   BEGIN
    PRINT (N'Ngày xóa sản phẩm phải sau ngày tạo')
    ROLLBACK TRANSACTION
   END;
END;

--KHACH_HANG: SDT của khách hàng phải là dãy có 10 số
CREATE TRIGGER TR_SDT ON KHACH_HANG
AFTER INSERT, UPDATE
AS
  DECLARE @sdt VARCHAR (15)
  SELECT @sdt = SDT FROM INSERTED
  IF LEN (@sdt) <> 10
  BEGIN
   PRINT (N'Số điện thoại không hợp lệ')
   ROLLBACK TRANSACTION
  END

--KHACH_HANG: Trigger kiểm tra tính duy nhất của số điện thoại của KH, không được trùng
CREATE TRIGGER TR_SDTDUYNHAT ON KHACH_HANG
AFTER INSERT, UPDATE
AS
 IF EXISTS (SELECT 1 FROM KHACH_HANG WHERE SDT = (SELECT SDT FROM INSERTED))
 BEGIN 
  PRINT (N'Số điện thoại đã tồn tại')
  ROLLBACK TRANSACTION
 END

--TON_KHO: Trigger kiểm tra nhân viên kiểm kê tồn kho phải có vai trò là NV Kho 
CREATE TRIGGER TR_NVKIEMKE ON TON_KHO
AFTER INSERT, UPDATE
AS 
BEGIN
    DECLARE @MaNVKiemKe CHAR(6)
    SELECT @MaNVKiemKe = MaNVKiemKe FROM inserted
    IF EXISTS (SELECT * FROM NHAN_VIEN WHERE VaiTro != N'Kho' AND @MaNVKiemKe = MaNV)
		BEGIN
			 RAISERROR(N'Chức vụ nhân viên kiểm kê không đúng quy định.', 16, 1)
			ROLLBACK TRANSACTION
		END
END

--PHIEU_DAT_HANG: Nhân viên lập phiếu đặt hàng phải có vai trò là Quản lý
CREATE TRIGGER TR_NVLAP_PDH ON PHIEU_DAT_HANG
AFTER INSERT, UPDATE
AS 
BEGIN
    DECLARE @MaNVLap CHAR(6)
    SELECT @MaNVLap = MaNVLap FROM inserted
    IF EXISTS (SELECT * FROM NHAN_VIEN WHERE VaiTro != N'Quản lý' AND @MaNVLap = MaNV)
		BEGIN
			 RAISERROR(N'Chức vụ nhân viên lập phiếu đặt hàng không đúng quy định.', 16, 1)
			ROLLBACK TRANSACTION
		END
END

--PHIEU_NHAP_HANG: Nhân viên lập phiếu nhập hàng phải có vai trò là NV Kho
CREATE TRIGGER TR_NVLAP_PNH ON PHIEU_NHAP_HANG
AFTER INSERT, UPDATE
AS 
BEGIN
    DECLARE @MaNVLap CHAR(6)
    SELECT @MaNVLap = MaNVLap FROM inserted
    IF EXISTS (SELECT * FROM NHAN_VIEN WHERE VaiTro != N'Kho' AND @MaNVLap = MaNV)
		BEGIN
			 RAISERROR(N'Chức vụ nhân viên lập phiếu nhập hàng không đúng quy định.', 16, 1)
			ROLLBACK TRANSACTION
		END
END

--DON_HANG: Đơn hàng đã có thông tin giao hàng không thể xóa hoặc thay đổi
CREATE TRIGGER TR_KHONGXOASUA_DH
ON DON_HANG
AFTER DELETE, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM THONG_TIN_GIAO_HANG TTGH
        JOIN DELETED d ON TTGH.MaDH = d.MaDH
    )
    BEGIN
        PRINT (N'Đơn hàng đã có thông tin giao hàng, không thể xóa hoặc thay đổi.')
        ROLLBACK TRANSACTION
    END
END

--PHIEU_NHAP_HANG: Ngày lập phiếu đặt không được sau ngày lập phiếu nhập
CREATE TRIGGER TR_KIEM_TRA_NGAY_LAP
ON PHIEU_NHAP_HANG
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM INSERTED PNH
        JOIN PHIEU_DAT_HANG PDH ON PNH.MaPhieuDatHang = PDH.MaPhieuDatHang
        WHERE PNH.NgayNhap < PDH.NgayDat
    )
    BEGIN
        PRINT (N'Ngày lập phiếu đặt hàng không được sau ngày lập phiếu nhập hàng.')
        ROLLBACK TRANSACTION
    END
END

--CHI_TIET_DAT_HANG: Loại sản phẩm khi đặt hàng phải tương ứng với nhà cung cấp của sản phẩm đó
CREATE TRIGGER TR_KIEM_TRA_NCC_SANPHAM
ON CHI_TIET_DAT_HANG
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM INSERTED CTDH
        JOIN SAN_PHAM SP ON CTDH.MaSP = SP.MaSP
        JOIN PHIEU_DAT_HANG PDH ON CTDH.MaPhieuDatHang = PDH.MaPhieuDatHang
        WHERE SP.MaNCC <> PDH.MaNCC
    )
    BEGIN
        PRINT (N'Nhà cung cấp không hợp lệ')
        ROLLBACK TRANSACTION
    END
END