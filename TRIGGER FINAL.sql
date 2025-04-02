--1. KHACH_HANG: SDT của khách hàng phải là dãy có 10 số
CREATE TRIGGER TR_SDT_KH ON KHACH_HANG
AFTER INSERT, UPDATE
AS
BEGIN
    DECLARE @sdt VARCHAR (15)
    SELECT @sdt = SDT FROM INSERTED
    IF LEN (@sdt) <> 10
    BEGIN
       PRINT (N'Số điện thoại không hợp lệ')
       ROLLBACK TRANSACTION
    END
END
-- Test trigger:
INSERT INTO KHACH_HANG VALUES ('KH0021', N'Hoàng Văn Ung', 'Ungvanhoang@258147', '09001122338', 'hoangvanung1414@gmail.com', N'147 Phạm Hùng, TP.Cà Mau');
UPDATE KHACH_HANG SET SDT='09123456788' WHERE MaKH = 'KH0001'

----------------------------------------------------------------------
--2. KHACH_HANG: Trigger kiểm tra tính duy nhất của số điện thoại của KH, không được trùng
CREATE TRIGGER TR_SDTDUYNHAT_KH ON KHACH_HANG
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM KHACH_HANG WHERE SDT = (SELECT SDT FROM INSERTED))
    BEGIN 
        PRINT (N'Số điện thoại đã tồn tại')
        ROLLBACK TRANSACTION
    END
 END
 --Test trigger:
INSERT INTO KHACH_HANG VALUES ('KH0021', N'Hoàng Văn Ung', 'Ungvanhoang@258147', '0900112233', 'hoangvanung1414@gmail.com', N'147 Phạm Hùng, TP.Cà Mau');
UPDATE KHACH_HANG SET SDT='0912345678' WHERE MAKH = 'KH0002'

----------------------------------------------------------------------
--3. NHAN_VIEN: SDT của nhân viên phải là dãy có 10 số
CREATE TRIGGER TR_SDT_NV ON NHAN_VIEN
AFTER INSERT, UPDATE
AS
BEGIN
    DECLARE @sodienthoai VARCHAR (15)
    SELECT @sodienthoai = SDT FROM INSERTED
    IF LEN (@sodienthoai) <> 10
    BEGIN
       PRINT (N'Số điện thoại không hợp lệ')
       ROLLBACK TRANSACTION
    END
END
--Test trigger:
INSERT INTO NHAN_VIEN VALUES ('NV0021', N'Lê Kim Uyên', N'Nữ', '09123456978', N'Thủ Đức', 'lekimuyen@gmail.com', N'Kho');
UPDATE NHAN_VIEN SET SDT = '09123456978' WHERE MaNV = 'NV0020';

----------------------------------------------------------------------
--4. NHAN_VIEN: Trigger kiểm tra tính duy nhất của số điện thoại của NV, không được trùng
CREATE TRIGGER TR_DUYNHATSDT_NV ON NHAN_VIEN
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM NHAN_VIEN WHERE SDT = (SELECT SDT FROM INSERTED))
    BEGIN 
        PRINT (N'Số điện thoại đã tồn tại')
        ROLLBACK TRANSACTION
    END
END
--Test trigger:
INSERT INTO NHAN_VIEN VALUES ('NV0021', N'Lê Kim Uyên', N'Nữ', '0912345697', N'Thủ Đức', 'lekimuyen@gmail.com', N'Kho');
UPDATE NHAN_VIEN SET SDT = '0912345697' WHERE MaNV = 'NV0019';

----------------------------------------------------------------------
--5. PHIEU_DAT_HANG: Nhân viên lập phiếu đặt hàng phải có vai trò là Quản lý
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
--Test trigger:
INSERT INTO PHIEU_DAT_HANG VALUES ('PDH021', '2025-03-20', 'NV0020', 'NCC002');
UPDATE PHIEU_DAT_HANG SET MaNVLap = 'NV0020' WHERE MaPhieuDatHang = 'PDH020';

----------------------------------------------------------------------
--6. PHIEU_NHAP_HANG: Nhân viên lập phiếu nhập hàng phải có vai trò là NV Kho
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
--Test trigger:
INSERT INTO PHIEU_NHAP_HANG VALUES ('PNH021', '2025-03-22', 'NV0008', 'PDH018', 'NCC006');
UPDATE PHIEU_NHAP_HANG SET MaNVLap = 'NV0008' WHERE MaPhieuNhap = 'PNH020';

----------------------------------------------------------------------
--7. PHIEU_NHAP_HANG: Ngày lập phiếu đặt không được sau ngày lập phiếu nhập
CREATE TRIGGER TR_KIEM_TRA_NGAY_LAP ON PHIEU_NHAP_HANG
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
--Test trigger:
INSERT INTO PHIEU_NHAP_HANG VALUES ('PNH021', '2025-03-16', 'NV0009', 'PDH018', 'NCC006');
UPDATE PHIEU_NHAP_HANG SET NgayNhap = '2025-03-16' WHERE MaPhieuNhap = 'PNH020';

----------------------------------------------------------------------
--8. PHIEU_NHAP_HANG: Mã NCC trong phiếu nhập phải trùng với mã NCC trong phiếu đặt mà nó thuộc về 
CREATE TRIGGER TR_KIEMTRA_NCC_PHIEU_NHAP ON PHIEU_NHAP_HANG
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM INSERTED I
        INNER JOIN PHIEU_DAT_HANG PDH ON I.MaPhieuDatHang = PDH.MaPhieuDatHang
        WHERE I.MaNCC <> PDH.MaNCC
    )
    BEGIN
        RAISERROR(N'Mã NCC trong Phiếu Nhập phải trùng với Mã NCC của Phiếu Đặt.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
--Test trigger:
INSERT INTO PHIEU_NHAP_HANG VALUES ('PNH021', '2025-03-22', 'NV0009', 'PDH018', 'NCC005');
UPDATE PHIEU_NHAP_HANG SET MaNCC = 'NCC005' WHERE MaPhieuNhap = 'PNH020';

----------------------------------------------------------------------
--9. CHI_TIET_DAT_HANG: Loại sản phẩm khi đặt hàng phải tương ứng với nhà cung cấp của sản phẩm đó
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
--Test trigger
UPDATE CHI_TIET_DAT_HANG SET MaSP = 'SP0003' WHERE MaPhieuDatHang = 'PDH002';
INSERT INTO CHI_TIET_DAT_HANG VALUES ('PDH002', 'SP0003', 40, 160000);

----------------------------------------------------------------------
--10. DANH_GIA_SP: Trigger chỉ cho phép khách hàng đánh giá đơn hàng của mình và ghi nhận đánh giá chỉ khi đơn hoàn thành
CREATE TRIGGER TR_DANHGIA 
ON DANH_GIA_SP
AFTER INSERT, UPDATE
AS
BEGIN
    DECLARE @MaSP CHAR(10), @MaDH CHAR(10), @MaKH CHAR(10), @TrangThaiGiao NVARCHAR(20)
    SELECT @MaSP = I.MaSP, @MaDH = I.MaDH, @MaKH = I.MaKH 
    FROM INSERTED I
    -- Kiểm tra trạng thái của đơn hàng trong THONG_TIN_GIAO_HANG
    SELECT @TrangThaiGiao = TrangThaiGiao 
    FROM THONG_TIN_GIAO_HANG 
    WHERE MaDH = @MaDH
    -- Kiểm tra xem khách hàng có phải là chủ của đơn hàng hay không
    IF NOT EXISTS (
        SELECT 1 
        FROM DON_HANG DH
        WHERE DH.MaDH = @MaDH AND DH.MaKH = @MaKH
    )
    BEGIN
        RAISERROR(N'Khách hàng chỉ có thể đánh giá sản phẩm thuộc đơn hàng của mình.', 16, 1)
        ROLLBACK TRANSACTION
        RETURN
    END
    -- Nếu trạng thái giao hàng không phải "Giao hàng thành công", ngăn chặn đánh giá
    IF @TrangThaiGiao <> N'Giao hàng thành công'
    BEGIN
        RAISERROR(N'Chỉ có thể đánh giá sản phẩm khi đơn hàng đã được giao.', 16, 1)
        ROLLBACK TRANSACTION
    END
END

--Test trigger 
INSERT INTO DANH_GIA_SP VALUES ('DG0007', 5, N'Xứng đáng với giá tiền, rất đáng mua!', '2025-03-16', 'KH0012', 'SP0005', 'DH0005');
UPDATE DANH_GIA_SP SET MaKH = 'KH0001' WHERE MaDH = 'DH0009';

INSERT INTO DANH_GIA_SP VALUES ('DG0007', 5, N'Xứng đáng với giá tiền, rất đáng mua!', '2025-03-16', 'KH0016', 'SP0005', 'DH0005');

----------------------------------------------------------------------
--11. SAN_PHAM: Ngày xóa sản phẩm phải sau ngày tạo
CREATE TRIGGER TR_NGAYXOA_SP ON SAN_PHAM
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
--Test trigger:
UPDATE SAN_PHAM SET NgayXoaSP = '2025/01/08' WHERE MaSP = 'SP0001';
INSERT INTO SAN_PHAM VALUES ('SP0016', N'Áo thun nam cotton', N'Áo thun nam cotton 100%, thoáng mát, không xù lông.', 199000, 56, '2025/01/10',  '2025/01/08', 'DM0001', 'NCC001'); 

----------------------------------------------------------------------
--12. DANH_MUC_SP: Ngày xóa danh mục sản phẩm phải sau ngày tạo
CREATE TRIGGER TR_NGAYXOA_DMSP ON DANH_MUC_SP
AFTER INSERT, UPDATE
AS
BEGIN
    DECLARE @ngaytaodm DATE, @ngayxoadm DATE
    SELECT @ngaytaodm = NgayTaoDM, @ngayxoadm = NgayXoaDM
    FROM INSERTED
    IF @NgayXoaDM IS NOT NULL AND @NgayTaoDM > @NgayXoaDM
    BEGIN
        PRINT (N'Ngày xóa danh mục sản phẩm phải sau ngày tạo')
        ROLLBACK TRANSACTION
    END;
END;
--Test trigger:
INSERT INTO DANH_MUC_SP VALUES ('DM0006', N'Áo khoác', N'Áo khoác bomber, áo khoác dạ, áo hoodie unisex.', 1, '2025/01/05', '2025/01/01');
UPDATE DANH_MUC_SP SET NgayXoaDM = '2025/01/01' WHERE MaDM = 'DM0005';
----------------------------------------------------------------------

--13. DON_HANG: Đơn hàng đã có thông tin giao hàng không thể xóa hoặc thay đổi
CREATE TRIGGER TR_KHONGXOASUA_DH ON DON_HANG
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
--Test trigger:
UPDATE DON_HANG SET NgayDatDon = GETDATE() WHERE MaDH = 'DH0001';
DELETE FROM DON_HANG WHERE MaDH = 'DH0002';

----------------------------------------------------------------------
--14. CHI_TIET_DON_HANG: Đơn giá bán không được lớn hơn giá niêm yết của sản phẩm 
CREATE TRIGGER TR_KIEM_TRA_DON_GIA ON CHI_TIET_DON_HANG
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM INSERTED I
        JOIN SAN_PHAM SP ON I.MaSP = SP.MaSP
        WHERE I.DonGia > SP.GiaNiemYet
    )
    BEGIN
        RAISERROR(N'Đơn giá bán không được lớn hơn giá niêm yết của sản phẩm.', 16, 1)
        ROLLBACK TRANSACTION
    END
END
--Test trigger:
INSERT INTO CHI_TIET_DON_HANG VALUES ('DH0001','SP0003','2','269000');
UPDATE CHI_TIET_DON_HANG SET DonGia = '500000' WHERE MaSP = 'SP0001';

----------------------------------------------------------------------
--15. CHI_TIET_NHAP_HANG: Cập nhật số lượng tồn khi thêm, xóa, sửa Chi tiết nhập hàng
CREATE TRIGGER TR_CAPNHAT_SLT_NHAPHANG
ON CHI_TIET_NHAP_HANG
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
     -- Khi thêm CT nhập hàng -> Cộng số lượng nhập vào số lượng tồn
    IF EXISTS (SELECT 1 FROM INSERTED) AND NOT EXISTS (SELECT 1 FROM DELETED)
    BEGIN
        UPDATE SP
        SET SP.SoLuongTon = SP.SoLuongTon + I.SoLuongNhap
        FROM SAN_PHAM SP
        INNER JOIN INSERTED I ON SP.MaSP = I.MaSP;
    END
    -- Khi xóa CT nhập hàng -> Trừ số lượng nhập ra khỏi số lượng tồn
    IF EXISTS (SELECT 1 FROM DELETED) AND NOT EXISTS (SELECT 1 FROM INSERTED)
    BEGIN
	UPDATE SP
        SET SP.SoLuongTon = SP.SoLuongTon - D.SoLuongNhap
        FROM SAN_PHAM SP
        INNER JOIN DELETED D ON SP.MaSP = D.MaSP;
    END
    -- Khi cập nhật CT nhập hàng -> Điều chỉnh lại số lượng tồn 
    IF EXISTS (SELECT 1 FROM INSERTED) AND EXISTS (SELECT 1 FROM DELETED)
    BEGIN
        UPDATE SAN_PHAM
        SET SoLuongTon = SoLuongTon + (I.SoLuongNhap - D.SoLuongNhap)
        FROM SAN_PHAM SP
        INNER JOIN INSERTED I ON SP.MaSP = I.MaSP
        INNER JOIN DELETED D ON SP.MaSP = D.MaSP;
    END
END;
--Test trigger:
INSERT INTO CHI_TIET_NHAP_HANG VALUES ('PNH020', 'SP0015', 50);
DELETE FROM CHI_TIET_NHAP_HANG WHERE MaPhieuNhap = 'PNH020' AND MaSP = 'SP0015';
UPDATE CHI_TIET_NHAP_HANG SET SoLuongNhap = 20 WHERE MaPhieuNhap = 'PNH001' AND MaSP = 'SP0001';

----------------------------------------------------------------------
--16. CHI_TIET_DON_HANG: Cập nhật số lượng tồn khi có khách đặt hàng
CREATE TRIGGER TR_CAPNHAT_SLT_DATHANG
ON CHI_TIET_DON_HANG
AFTER INSERT
AS
BEGIN
    UPDATE SAN_PHAM
    SET SoLuongTon = SoLuongTon - I.SoLuong
    FROM SAN_PHAM SP
    INNER JOIN INSERTED I ON SP.MaSP = I.MaSP;
END;

----------------------------------------------------------------------
--17. SAN_PHAM: Thông báo khi số lượng tồn <10
CREATE TRIGGER TR_TB_SAP_HET_HANG
ON SAN_PHAM
AFTER UPDATE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM INSERTED WHERE SoLuongTon < 10)
    BEGIN
        PRINT 'Cảnh báo: Sản phẩm sắp hết hàng (tồn kho <10)';
    END
END;

----------------------------------------------------------------------
--18. CHI_TIET_DON_HANG: Kiểm tra số lượng tồn khi khách hàng đặt hàng
CREATE TRIGGER TR_KT_TONKHO
ON CHI_TIET_DON_HANG
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM INSERTED I
        INNER JOIN SAN_PHAM SP ON I.MaSP = SP.MaSP
        WHERE I.SoLuong > SP.SoLuongTon
    )
    BEGIN
        PRINT (N'Số lượng tồn kho không đủ để đặt hàng!');
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
--Test trigger: 
SELECT * FROM SAN_PHAM
SELECT * FROM CHI_TIET_DON_HANG
INSERT INTO CHI_TIET_DON_HANG VALUES ('DH0022', 'SP0005','27','269000')

----------------------------------------------------------------------
--19. DON_HANG: Hoàn lại số lượng tồn khi đơn bị hủy
CREATE TRIGGER TR_HOANLAI_DONHANG
ON DON_HANG
AFTER DELETE
AS
BEGIN
    UPDATE SAN_PHAM
    SET SoLuongTon = SoLuongTon + CTDH.SoLuong
    FROM SAN_PHAM SP
    INNER JOIN CHI_TIET_DON_HANG CTDH ON SP.MaSP = CTDH.MaSP
    INNER JOIN deleted D ON D.MaDH = CTDH.MaDH;
END;




