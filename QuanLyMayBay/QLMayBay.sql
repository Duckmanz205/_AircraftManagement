-- ======================================================
-- PHẦN 1: KHỞI TẠO DATABASE & CẤU TRÚC BẢNG
-- ======================================================
CREATE DATABASE QUANLYMAYBAY;
GO
USE QUANLYMAYBAY;
GO

-- 1. Bảng Chức Vụ
CREATE TABLE CHUCVU (
    MACV CHAR(10) NOT NULL,
    TENCV NVARCHAR(50),
    CONSTRAINT PK_CV PRIMARY KEY (MACV)
);

-- 2. Bảng Nhân Viên
CREATE TABLE NHANVIEN (
    MANV CHAR(10) NOT NULL,
    TENNV NVARCHAR(50),
    SDT VARCHAR(15),
    MACV CHAR(10),
    MATKHAU VARCHAR(50),
    CONSTRAINT PK_NV PRIMARY KEY (MANV),
    CONSTRAINT FK_NV_CV FOREIGN KEY (MACV) REFERENCES CHUCVU(MACV)
);

-- 3. Bảng Khách Hàng
CREATE TABLE KHACHHANG (
    MAKH CHAR(10) NOT NULL,
    TENKH NVARCHAR(50),
    EMAIL VARCHAR(100),
    MATKHAU VARCHAR(50),
    SDT VARCHAR(20),
    DIACHI NVARCHAR(100),
    GTINH NVARCHAR(3),
    NGSINH DATE,
    QUOCGIA NVARCHAR(50),
    CONSTRAINT PK_KH PRIMARY KEY (MAKH)
);

-- 4. Bảng Máy Bay
CREATE TABLE MAYBAY (
    MAMB CHAR(10) NOT NULL,
    TENMB NVARCHAR(50),
    HANG NVARCHAR(50),
    TONGSOGHE INT,
    CONSTRAINT PK_MB PRIMARY KEY (MAMB)
);

-- 5. Bảng Cấu Hình Ghế
CREATE TABLE CAUHINH_GHE (
    MACG CHAR(10) NOT NULL,
    MAMB CHAR(10) NOT NULL,
    HANGGHE NVARCHAR(20) NOT NULL,
    SOLUONG INT,
    CONSTRAINT PK_CG PRIMARY KEY (MACG),
    CONSTRAINT FK_CG_MB FOREIGN KEY (MAMB) REFERENCES MAYBAY(MAMB)
);

-- 6. Bảng Sân Bay
CREATE TABLE SANBAY (
    MASB CHAR(10) NOT NULL,
    TENSB NVARCHAR(50),
    THANHPHO NVARCHAR(50),
    CONSTRAINT PK_SB PRIMARY KEY (MASB)
);

-- 7. Bảng Chuyến Bay
CREATE TABLE CHUYENBAY (
    MACB CHAR(10) NOT NULL,
    TRANGTHAI NVARCHAR(20),
    MAMB CHAR(10),
    CONSTRAINT PK_CB PRIMARY KEY (MACB),
    CONSTRAINT FK_CB_MB FOREIGN KEY (MAMB) REFERENCES MAYBAY(MAMB)
);

-- 8. Bảng Lộ Trình
CREATE TABLE LOTRINH (
    MALT CHAR(10) NOT NULL,
    MACB CHAR(10) NOT NULL,
    SBDI CHAR(10) NOT NULL,
    SBDEN CHAR(10) NOT NULL,
    GIOCATCANH DATETIME NOT NULL,
    GIOHACANH DATETIME NOT NULL,
    CONSTRAINT PK_LT PRIMARY KEY (MALT),
    CONSTRAINT FK_LT_CB FOREIGN KEY (MACB) REFERENCES CHUYENBAY(MACB),
    CONSTRAINT FK_LT_SBDI FOREIGN KEY (SBDI) REFERENCES SANBAY(MASB),
    CONSTRAINT FK_LT_SBDEN FOREIGN KEY (SBDEN) REFERENCES SANBAY(MASB)
);

-- 9. Bảng Ghế
CREATE TABLE GHE (
    MAGHE CHAR(10) NOT NULL,
    MAMB CHAR(10) NOT NULL,
    TENGHE NVARCHAR(10),
    HANGGHE NVARCHAR(20),
    CONSTRAINT PK_GHE PRIMARY KEY (MAGHE),
    CONSTRAINT FK_GHE_MB FOREIGN KEY (MAMB) REFERENCES MAYBAY(MAMB)
);

-- 10. Bảng Hạng Ghế & Giá
CREATE TABLE HANGGHE_GIA (
    MAHG CHAR(10) NOT NULL,
    MACB CHAR(10) NOT NULL,
    HANGGHE NVARCHAR(20),
    GIA_COSO MONEY,
    CONSTRAINT PK_HGG PRIMARY KEY (MAHG),
    CONSTRAINT FK_HGG_CB FOREIGN KEY (MACB) REFERENCES CHUYENBAY(MACB)
);

-- 11. Bảng Vé Máy Bay
CREATE TABLE VEMAYBAY (
    MAVE CHAR(10) NOT NULL,
    MAGHE CHAR(10) NOT NULL,
    MAHG CHAR(10),
    GIAVE MONEY,
    MACB CHAR(10),
    MANV CHAR(10),
    CONSTRAINT PK_VMB PRIMARY KEY (MAVE),
    CONSTRAINT FK_VMB_GHE FOREIGN KEY (MAGHE) REFERENCES GHE(MAGHE),
    CONSTRAINT FK_VMB_HGG FOREIGN KEY (MAHG) REFERENCES HANGGHE_GIA(MAHG),
    CONSTRAINT FK_VMB_CB FOREIGN KEY (MACB) REFERENCES CHUYENBAY(MACB),
    CONSTRAINT FK_VMB_NV FOREIGN KEY (MANV) REFERENCES NHANVIEN(MANV)
);

-- 12. Bảng Giỏ Hàng
CREATE TABLE GIOHANG (
    MAGH CHAR(10) NOT NULL,
    MAKH CHAR(10) NOT NULL,
    NGAYTAO DATETIME,
    TRANGTHAI NVARCHAR(20),
    CONSTRAINT PK_GH PRIMARY KEY (MAGH),
    CONSTRAINT FK_GH_KH FOREIGN KEY (MAKH) REFERENCES KHACHHANG(MAKH)
);

-- 13. Bảng Phiếu Đặt Vé
CREATE TABLE PHIEUDATVE (
    MAPHIEU CHAR(10) NOT NULL,
    NGLAP DATE,
    MANV CHAR(10),
    MAKH CHAR(10),
    TRANGTHAI NVARCHAR(30),
    MAGH CHAR(10),
    CONSTRAINT PK_PDV PRIMARY KEY (MAPHIEU),
    CONSTRAINT FK_PDV_NV FOREIGN KEY (MANV) REFERENCES NHANVIEN(MANV),
    CONSTRAINT FK_PDV_KH FOREIGN KEY (MAKH) REFERENCES KHACHHANG(MAKH),
    CONSTRAINT FK_PDV_GH FOREIGN KEY (MAGH) REFERENCES GIOHANG(MAGH)
);

-- 14. Bảng Chi Tiết Vé
CREATE TABLE CHITIETVE (
    MAVE CHAR(10) NOT NULL,
    MAPHIEU CHAR(10) NOT NULL,
    NGAYDAT DATE,
    GIATIEN MONEY,
    CONSTRAINT PK_CTV PRIMARY KEY (MAVE, MAPHIEU),
    CONSTRAINT FK_CTV_VE FOREIGN KEY (MAVE) REFERENCES VEMAYBAY(MAVE),
    CONSTRAINT FK_CTV_PDV FOREIGN KEY (MAPHIEU) REFERENCES PHIEUDATVE(MAPHIEU)
);

-- 15. Bảng Hành Lý
CREATE TABLE HANHLY (
    MAHL CHAR(10) NOT NULL,
    MAVE CHAR(10) NOT NULL,
    MACB CHAR(10) NOT NULL,
    LOAIHL NVARCHAR(20),
    KHOILUONG FLOAT,
    KICHTHUOC FLOAT,
    CONSTRAINT PK_HL PRIMARY KEY (MAHL),
    CONSTRAINT FK_HL_KH FOREIGN KEY (MAVE) REFERENCES VEMAYBAY(MAVE),
    CONSTRAINT FK_HL_CB FOREIGN KEY (MACB) REFERENCES CHUYENBAY(MACB)
);

-- 16. Bảng Thống Kê Doanh Thu
CREATE TABLE THONGKE_DOANHTHU (
    MACB CHAR(10) NOT NULL,
    NGAY DATE NOT NULL,
    TONGDOANHTHU MONEY,
    SOLUONGVE INT,
    CONSTRAINT PK_TK PRIMARY KEY (MACB, NGAY),
    CONSTRAINT FK_TK_CB FOREIGN KEY (MACB) REFERENCES CHUYENBAY(MACB)
);

-- 17. Bảng Check-in
CREATE TABLE CHECKIN (
    MACHECKIN CHAR(10) NOT NULL,
    MAVE CHAR(10) NOT NULL,
    MAKH CHAR(10) NOT NULL,
    MACB CHAR(10) NOT NULL,
    TRANGTHAI NVARCHAR(30),
    THOIGIAN_CHECKIN DATETIME,
    CONSTRAINT PK_CI PRIMARY KEY (MACHECKIN),
    CONSTRAINT FK_CI_VE FOREIGN KEY (MAVE) REFERENCES VEMAYBAY(MAVE),
    CONSTRAINT FK_CI_KH FOREIGN KEY (MAKH) REFERENCES KHACHHANG(MAKH),
    CONSTRAINT FK_CI_CB FOREIGN KEY (MACB) REFERENCES CHUYENBAY(MACB)
);

-- 18. Bảng Chi Tiết Giỏ Hàng
CREATE TABLE GIOHANG_CHITIET (
    MAGH CHAR(10) NOT NULL,
    MACB CHAR(10) NOT NULL,
    SOLUONG INT,
    GIATIEN MONEY,
    THOIGIANGIU DATETIME,
    CONSTRAINT PK_GHCT PRIMARY KEY (MAGH, MACB),
    CONSTRAINT FK_GHCT_GH FOREIGN KEY (MAGH) REFERENCES GIOHANG(MAGH),
    CONSTRAINT FK_GHCT_CB FOREIGN KEY (MACB) REFERENCES CHUYENBAY(MACB)
);

-- 19. Bảng Giỏ Hàng Hành Khách
CREATE TABLE GIOHANG_HANHKHACH (
    MAHK CHAR(20) NOT NULL,
    SOGHE CHAR(10) NOT NULL,
    MAGH CHAR(10) NOT NULL,
    MACB CHAR(10) NOT NULL,
    HANGGHE NVARCHAR(20) NOT NULL,
    TENHANHKHACH NVARCHAR(100),
    NGAYSINH DATE,
    GIOITINH NVARCHAR(3),
    EMAIL VARCHAR(100),
    SDT VARCHAR(10),
    HANGLY_XACHTAY INT,
    HANHLYKYGUI INT,
    CONSTRAINT PK_GHHK PRIMARY KEY (MAHK),
    CONSTRAINT FK_GHKH_GH FOREIGN KEY (MAGH) REFERENCES GIOHANG(MAGH),
    CONSTRAINT FK_GHKH_CB FOREIGN KEY (MACB) REFERENCES CHUYENBAY(MACB)
);
GO

-- ======================================================
-- PHẦN 2: CHÈN DỮ LIỆU MẪU
-- ======================================================

-- Dữ liệu Chức vụ
INSERT INTO CHUCVU VALUES
('CV01', N'Nhân viên bán vé'), ('CV02', N'Nhân viên check-in'),
('CV03', N'Tiếp viên trưởng'), ('CV04', N'Phi công cơ trưởng'),
('CV05', N'Quản lý cấp cao'), ('CV06', N'Kỹ thuật viên bảo trì'),
('CV07', N'Nhân viên hành lý'), ('CV08', N'Nhân viên kế toán'),
('CV09', N'Giám đốc sân bay'), ('CV10', N'Nhân viên Marketing');

-- Dữ liệu Nhân viên
INSERT INTO NHANVIEN VALUES
('NV01', N'Nguyễn Văn A', '0901234567', 'CV01', '123456'),
('NV02', N'Lê Thị B', '0902345678', 'CV02', '123456'),
('NV03', N'Trần Văn C', '0903456789', 'CV03', '123456'),
('NV04', N'Phạm Văn D', '0904567890', 'CV04', 'pilot123'),
('NV05', N'Hoàng Thị E', '0905678901', 'CV05', 'admin123'),
('NV06', N'Võ Minh F', '0906789012', 'CV06', 'tech123'),
('NV07', N'Đặng Thị G', '0907890123', 'CV07', 'bag123'),
('NV08', N'Bùi Văn H', '0908901234', 'CV08', 'acc123'),
('NV09', N'Tô Thị I', '0909012345', 'CV09', 'admin123'),
('NV10', N'Lý Văn K', '0900123456', 'CV10', 'mark123');

-- Dữ liệu Khách hàng
INSERT INTO KHACHHANG VALUES
('KH01', N'Nguyễn Minh Khoa', 'khoa@gmail.com', '123456', '0911111111', N'Hà Nội', N'Nam', '1990-05-12', N'Việt Nam'),
('KH02', N'Lê Thanh Hoa', 'hoa@gmail.com', 'hoa2025', '0922222222', N'Hồ Chí Minh', N'Nữ', '1995-07-20', N'Việt Nam'),
('KH03', N'John Smith', 'john@gmail.com', 'johnpass', '0933333333', N'New York', N'Nam', '1988-09-15', N'Mỹ'),
('KH04', N'Nguyễn Văn Nam', 'nam@gmail.com', 'namvip', '0944444444', N'Đà Nẵng', N'Nam', '1992-01-30', N'Việt Nam'),
('KH05', N'Lý Thu Hà', 'ha@gmail.com', 'ha2025', '0955555555', N'Hải Phòng', N'Nữ', '1998-11-25', N'Việt Nam'),
('KH06', N'Trần Đức Tài', 'tai@gmail.com', 'tai123', '0966666666', N'Cần Thơ', N'Nam', '1985-03-10', N'Việt Nam'),
('KH07', N'Mai Hồng Nhung', 'nhung@gmail.com', 'nhungvip', '0977777777', N'Huế', N'Nữ', '1993-08-05', N'Việt Nam'),
('KH08', 'David Lee', 'david@gmail.com', 'davidp', '0988888888', N'Seoul', N'Nam', '1991-12-24', N'Hàn Quốc'),
('KH09', N'Phan Thúy An', 'an@gmail.com', 'anpass', '0999999999', N'Quy Nhơn', N'Nữ', '2000-04-17', N'Việt Nam'),
('KH10', N'Nguyễn Hùng Sơn', 'son@gmail.com', 'sonpass', '0900000000', N'Nha Trang', N'Nam', '1980-06-28', N'Việt Nam');

-- Dữ liệu Máy bay
INSERT INTO MAYBAY VALUES
('MB01', N'Airbus A320', N'Airbus', 180), ('MB02', N'Boeing 737-800', N'Boeing', 150),
('MB03', N'Airbus A321', N'Airbus', 220), ('MB04', N'Boeing 787-9', N'Boeing', 280),
('MB05', N'ATR 72-600', N'ATR', 80), ('MB06', N'Embraer 190', N'Embraer', 100),
('MB07', N'Airbus A350', N'Airbus', 350), ('MB08', N'Boeing 777-300ER', N'Boeing', 380),
('MB09', N'Bombardier CRJ900', N'Bombardier', 90), ('MB10', N'Airbus A330', N'Airbus', 300);

-- Dữ liệu Cấu hình ghế
INSERT INTO CAUHINH_GHE VALUES
('CG01', 'MB01', N'Phổ thông', 170), ('CG02', 'MB01', N'Thương gia', 10),
('CG03', 'MB02', N'Phổ thông', 140), ('CG04', 'MB02', N'Thương gia', 10),
('CG05', 'MB03', N'Phổ thông', 200), ('CG06', 'MB03', N'Thương gia', 20),
('CG07', 'MB04', N'Phổ thông', 250), ('CG08', 'MB04', N'Thương gia', 30),
('CG09', 'MB05', N'Phổ thông', 80), ('CG10', 'MB07', N'Hạng nhất', 10);

-- Dữ liệu Sân bay
INSERT INTO SANBAY VALUES
('SB01', N'Nội Bài', N'Hà Nội'), ('SB02', N'Tân Sơn Nhất', N'Hồ Chí Minh'),
('SB03', N'Đà Nẵng', N'Đà Nẵng'), ('SB04', N'Cam Ranh', N'Khánh Hòa'),
('SB05', N'Cát Bi', N'Hải Phòng'), ('SB06', N'Cần Thơ', N'Cần Thơ'),
('SB07', N'Phú Bài', N'Huế'), ('SB08', N'Phú Quốc', N'Kiên Giang'),
('SB09', N'Vinh', N'Nghệ An'), ('SB10', N'Liên Khương', N'Lâm Đồng');

-- Dữ liệu Chuyến bay
INSERT INTO CHUYENBAY VALUES
('CB01', N'Đang bay', 'MB01'), ('CB02', N'Đang bay', 'MB02'),
('CB03', N'Đang bay', 'MB03'), ('CB04', N'Đang bay', 'MB04'),
('CB05', N'Hủy', 'MB05'),      ('CB06', N'Đang bay', 'MB06'),
('CB07', N'Đang bay', 'MB07'), ('CB08', N'Đang bay', 'MB08'),
('CB09', N'Đang bay', 'MB09'), ('CB10', N'Đang bay', 'MB10');

-- Dữ liệu Lộ trình
INSERT INTO LOTRINH VALUES
('LT01', 'CB01', 'SB02', 'SB01', '2025-12-29 08:00:00', '2025-12-29 10:00:00'),
('LT02', 'CB02', 'SB03', 'SB02', '2025-12-29 14:00:00', '2025-12-29 16:30:00'),
('LT03', 'CB03', 'SB01', 'SB03', '2025-12-30 09:00:00', '2025-12-30 11:00:00'),
('LT04', 'CB04', 'SB01', 'SB02', '2025-12-30 11:00:00', '2025-12-30 13:00:00'),
('LT05', 'CB05', 'SB05', 'SB01', '2025-12-31 06:00:00', '2025-12-31 07:30:00'),
('LT06', 'CB06', 'SB03', 'SB06', '2026-01-01 12:00:00', '2026-01-01 13:30:00'),
('LT07', 'CB07', 'SB02', 'SB01', '2026-01-02 15:00:00', '2026-01-02 17:00:00'),
('LT08', 'CB08', 'SB02', 'SB03', '2026-01-03 18:00:00', '2026-01-03 20:30:00'),
('LT09', 'CB09', 'SB07', 'SB02', '2026-01-04 07:30:00', '2026-01-04 09:00:00'),
('LT10', 'CB10', 'SB03', 'SB05', '2026-01-05 10:00:00', '2026-01-05 11:30:00');

-- Dữ liệu Ghế
INSERT INTO GHE VALUES
('GH01','MB01','12A',N'Phổ thông'), ('GH02','MB01','12B',N'Phổ thông'),
('GH03','MB01','01A',N'Thương gia'), ('GH04','MB02','14B',N'Phổ thông'),
('GH05','MB03','15C',N'Phổ thông'), ('GH06','MB04','05D',N'Phổ thông'),
('GH07','MB06','10A',N'Phổ thông'), ('GH08','MB07','01D',N'Hạng nhất'),
('GH09','MB08','20E',N'Phổ thông'), ('GH10','MB09','03B',N'Thương gia');

-- Dữ liệu Giá vé cơ bản
INSERT INTO HANGGHE_GIA VALUES
('HG01', 'CB01', N'Phổ thông', 1950000), ('HG02', 'CB01', N'Thương gia', 4500000),
('HG03', 'CB02', N'Phổ thông', 1500000), ('HG04', 'CB02', N'Thương gia', 3800000),
('HG05', 'CB03', N'Phổ thông', 1800000), ('HG06', 'CB04', N'Phổ thông', 2000000),
('HG07', 'CB04', N'Thương gia', 4600000), ('HG08', 'CB06', N'Phổ thông', 1300000),
('HG09', 'CB07', N'Thương gia', 4000000), ('HG10', 'CB09', N'Phổ thông', 1750000),
('HG11', 'CB07', N'Hạng nhất', 5500000);

-- Dữ liệu Vé đã bán
INSERT INTO VEMAYBAY VALUES
('VE01','GH01','HG01',1950000,'CB01','NV01'), ('VE02','GH02','HG01',2050000,'CB01','NV01'),
('VE03','GH03','HG02',4800000,'CB01','NV02'), ('VE04','GH04','HG03',1500000,'CB02','NV03'),
('VE05','GH05','HG05',1800000,'CB03','NV04'), ('VE06','GH06','HG06',2000000,'CB04','NV01'),
('VE07','GH07','HG08',1300000,'CB06','NV05'), ('VE08','GH08','HG11',5000000,'CB07','NV05'),
('VE09','GH09','HG04',3900000,'CB08','NV02'), ('VE10','GH10','HG10',1750000,'CB09','NV03');

-- Dữ liệu Giỏ hàng
INSERT INTO GIOHANG VALUES
('GH01', 'KH01', '2025-11-28 10:00:00', N'Đã thanh toán'), 
('GH02', 'KH02', '2025-11-28 11:30:00', N'Đã thanh toán'), 
('GH03', 'KH03', '2025-11-29 15:45:00', N'Đã thanh toán'), 
('GH04', 'KH04', '2025-11-29 09:00:00', N'Đã thanh toán'), 
('GH05', 'KH05', '2025-11-27 18:20:00', N'Đã thanh toán'), 
('GH06', 'KH06', '2025-11-27 14:00:00', N'Đã thanh toán'), 
('GH07', 'KH07', '2025-11-26 12:00:00', N'Đã thanh toán'), 
('GH08', 'KH08', '2025-11-29 20:00:00', N'Đang chọn'),
('GH09', 'KH09', '2025-11-25 08:00:00', N'Đã hết hạn'),
('GH10', 'KH10', '2025-11-29 21:30:00', N'Đang chọn');

-- Dữ liệu Phiếu đặt vé
INSERT INTO PHIEUDATVE VALUES
('PD01', '2025-11-28', 'NV01', 'KH01', N'Đã thanh toán', 'GH01'), 
('PD02', '2025-11-28', 'NV01', 'KH02', N'Đã thanh toán', 'GH02'), 
('PD03', '2025-11-29', 'NV02', 'KH03', N'Đã thanh toán', 'GH01'), 
('PD04', '2025-11-29', 'NV03', 'KH04', N'Hủy', 'GH04'),
('PD05', '2025-11-27', 'NV04', 'KH05', N'Đã thanh toán', 'GH03'),
('PD06', '2025-11-27', 'NV05', 'KH06', N'Đã thanh toán', 'GH02'), 
('PD07', '2025-11-26', 'NV05', 'KH07', N'Đã thanh toán', 'GH05'), 
('PD08', '2025-11-26', 'NV02', 'KH08', N'Đang xử lý', 'GH07'), 
('PD09', '2025-11-25', 'NV03', 'KH09', N'Đã thanh toán', 'GH06'), 
('PD10', '2025-11-29', 'NV04', 'KH10', N'Đang xử lý', 'GH10');

-- Dữ liệu Chi tiết vé
INSERT INTO CHITIETVE VALUES
('VE01', 'PD01', '2025-11-28', 1950000), ('VE02', 'PD01', '2025-11-28', 2050000),
('VE03', 'PD03', '2025-11-29', 4800000), ('VE04', 'PD04', '2025-11-29', 1500000),
('VE05', 'PD05', '2025-11-27', 1800000), ('VE06', 'PD02', '2025-11-28', 2000000),
('VE07', 'PD06', '2025-11-27', 1300000), ('VE08', 'PD07', '2025-11-26', 5000000),
('VE09', 'PD08', '2025-11-26', 3900000), ('VE10', 'PD09', '2025-11-25', 1750000);

-- Dữ liệu Hành lý
INSERT INTO HANHLY VALUES
('HL01', 'VE01', 'CB01', N'Xách tay', 7, 50), ('HL02', 'VE06', 'CB04', N'Ký gửi', 20, 100),
('HL03', 'VE03', 'CB01', N'Ký gửi', 25, 120), ('HL04', 'VE04', 'CB02', N'Xách tay', 10, 60),
('HL05', 'VE05', 'CB03', N'Ký gửi', 15, 80), ('HL06', 'VE07', 'CB06', N'Xách tay', 5, 40),
('HL07', 'VE08', 'CB07', N'Ký gửi', 30, 150), ('HL08', 'VE09', 'CB08', N'Xách tay', 8, 55),
('HL09', 'VE10', 'CB09', N'Ký gửi', 12, 70), ('HL10', 'VE02', 'CB01', N'Xách tay', 6, 45);

-- Dữ liệu Thống kê ban đầu
INSERT INTO THONGKE_DOANHTHU VALUES
('CB01', '2025-11-28', 4000000, 2), ('CB01', '2025-11-29', 4800000, 1),
('CB02', '2025-11-28', 1500000, 1), ('CB03', '2025-11-27', 1800000, 1),
('CB04', '2025-11-29', 2000000, 1), ('CB06', '2025-11-27', 1300000, 1),
('CB07', '2025-11-26', 5000000, 1), ('CB08', '2025-11-26', 3900000, 1),
('CB09', '2025-11-25', 1750000, 1), ('CB10', '2025-11-29', 0, 0);

-- Dữ liệu Chi tiết giỏ hàng
INSERT INTO GIOHANG_CHITIET (MAGH, MACB, SOLUONG, GIATIEN, THOIGIANGIU) VALUES
('GH01', 'CB01', 1, 4500000, DATEADD(MINUTE, 15, '2025-11-28 10:00:00')), 
('GH03', 'CB04', 2, 4000000, DATEADD(MINUTE, 15, '2025-11-29 15:45:00')),
('GH05', 'CB09', 1, 1950000, DATEADD(MINUTE, 15, '2025-11-27 18:20:00')),
('GH08', 'CB01', 3, 5850000, DATEADD(MINUTE, 15, '2025-11-29 20:00:00')),
('GH10', 'CB10', 1, 2200000, DATEADD(MINUTE, 15, '2025-11-29 21:30:00')),
('GH02', 'CB02', 1, 1700000, '2025-11-28 11:45:00'),
('GH04', 'CB03', 2, 3600000, '2025-11-29 09:15:00'),
('GH06', 'CB08', 1, 3800000, '2025-11-27 14:15:00'),
('GH07', 'CB06', 1, 1300000, '2025-11-26 12:15:00'),
('GH09', 'CB01', 1, 4500000, '2025-11-25 08:15:00');

-- Dữ liệu Hành khách trong giỏ hàng
INSERT INTO GIOHANG_HANHKHACH (MAHK, SOGHE, MAGH, MACB, HANGGHE, TENHANHKHACH, NGAYSINH, GIOITINH, EMAIL, SDT, HANGLY_XACHTAY, HANHLYKYGUI) VALUES
('HK01GH01', '01A', 'GH01', 'CB01', N'Thương gia', N'Nguyễn Minh Khoa', '1990-05-12', N'Nam', 'khoa@gmail.com',   '0911111111', 0, 1),
('HK01GH03', '10F', 'GH03', 'CB04', N'Phổ thông',  N'John Smith',       '1988-09-15', N'Nam', 'john@gmail.com',   '0933333333', 0, 0),
('HK02GH03', '10E', 'GH03', 'CB04', N'Phổ thông',  N'Mary Jane',        '1995-02-20', N'Nữ',  'mary@example.com', '0933333334', 0, 0),
('HK01GH05', '05C', 'GH05', 'CB09', N'Phổ thông',  N'Lý Thu Hà',        '1998-11-25', N'Nữ',  'ha@gmail.com',     '0955555555', 1, 0),
('HK01GH08', '20A', 'GH08', 'CB01', N'Phổ thông',  N'David Lee',        '1991-12-24', N'Nam', 'david@gmail.com',  '0988888888', 0, 0),
('HK02GH08', '20B', 'GH08', 'CB01', N'Phổ thông',  N'Lee Min Ho',       '1987-06-22', N'Nam', 'lmh@example.com',  '0988888881', 0, 0),
('HK03GH08', '20C', 'GH08', 'CB01', N'Phổ thông',  N'Kim Ji Won',       '1992-10-19', N'Nữ',  'kjw@example.com',  '0988888882', 0, 0),
('HK01GH10', '15D', 'GH10', 'CB10', N'Phổ thông',  N'Nguyễn Hùng Sơn',  '1980-06-28', N'Nam', 'son@gmail.com',    '0900000000', 0, 2),
('HK01GH02', '12A', 'GH02', 'CB02', N'Phổ thông',  N'Lê Thanh Hoa',     '1995-07-20', N'Nữ',  'hoa@gmail.com',    '0922222222', 1, 0),
('HK01GH04', '18F', 'GH04', 'CB03', N'Phổ thông',  N'Nguyễn Văn Nam',   '1992-01-30', N'Nam', 'nam@gmail.com',    '0944444444', 0, 0),
('HK01GH06', '10A', 'GH06', 'CB08', N'Phổ thông',  N'Trần Đức Tài',     '1985-03-10', N'Nam', 'tai@gmail.com',    '0966666666', 0, 1);
GO

-- Cập nhật giờ bay (Chỉ để đảm bảo các Proc liên quan đến thời gian chạy đúng)
UPDATE LOTRINH
SET GIOCATCANH = DATEADD(HOUR, 12, GETDATE()),
    GIOHACANH = DATEADD(HOUR, 14, GETDATE())
WHERE MACB = 'CB01';
GO

-- ======================================================
-- PHẦN 3: ĐỊNH NGHĨA CÁC RÀNG BUỘC
-- ======================================================

-- 1. Bảng Khách Hàng
ALTER TABLE KHACHHANG
ADD CONSTRAINT DF_KH_QG DEFAULT N'Việt Nam' FOR QUOCGIA,
    CONSTRAINT CHK_KH_GTINH CHECK (GTINH IN (N'Nam', N'Nữ', N'Khác'));

-- 2. Bảng Cấu Hình Ghế
ALTER TABLE CAUHINH_GHE
ADD CONSTRAINT UNQ_CG UNIQUE (MAMB, HANGGHE);

-- 3. Bảng Giỏ Hàng
ALTER TABLE GIOHANG
ADD CONSTRAINT DF_GH_NGAYTAO DEFAULT GETDATE() FOR NGAYTAO,
    CONSTRAINT DF_GH_TRANGTHAI DEFAULT N'Đang chọn' FOR TRANGTHAI;

-- 4. Bảng Chi Tiết Giỏ Hàng
ALTER TABLE GIOHANG_CHITIET
ADD CONSTRAINT DF_GHCT_SL DEFAULT 1 FOR SOLUONG,
    CONSTRAINT DF_GHCT_TIME DEFAULT DATEADD(MINUTE, 15, GETDATE()) FOR THOIGIANGIU;

-- 5. Bảng Giỏ Hàng Hành Khách
ALTER TABLE GIOHANG_HANHKHACH
ADD CONSTRAINT DF_GHKH_XACHTAY DEFAULT 0 FOR HANGLY_XACHTAY,
    CONSTRAINT DF_GHKH_KYGUI DEFAULT 0 FOR HANHLYKYGUI;

-- 6. Bảng Chuyến Bay
ALTER TABLE CHUYENBAY
ADD CONSTRAINT CHK_CB_TRANGTHAI CHECK (TRANGTHAI IN (N'Đang bay', N'Chờ bay', N'Đã hạ cánh', N'Hủy'));
GO

-- ======================================================
-- PHẦN 4: CÁC THỦ TỤC, HÀM, TRIGGER
-- ======================================================

-- ======================================================
-- CHỨC NĂNG QUẢN TRỊ HỆ THỐNG
-- ======================================================
-- 1. Proc: Backup Database
CREATE PROCEDURE sp_BackupDatabase
    @DuongDanFile NVARCHAR(255),
    @LoaiBackup VARCHAR(10)
AS
BEGIN
    DECLARE @DbName NVARCHAR(50) = DB_NAME();
    
    -- Xử lý Backup Full
    IF @LoaiBackup = 'full'
    BEGIN
        BACKUP DATABASE @DbName 
        TO DISK = @DuongDanFile 
        WITH INIT, NAME = 'Full Backup';
    END
    
    -- Xử lý Backup Differential (Khác biệt)
    ELSE IF @LoaiBackup = 'diff'
    BEGIN
        BACKUP DATABASE @DbName 
        TO DISK = @DuongDanFile 
        WITH DIFFERENTIAL, NAME = 'Diff Backup';
    END
    
    -- Xử lý Backup Log
    ELSE IF @LoaiBackup = 'log'
    BEGIN
        BACKUP LOG @DbName 
        TO DISK = @DuongDanFile 
        WITH NAME = 'Transaction Log Backup';
    END
END;
GO

-- 2. Trigger: Bảo vệ Giám đốc sân bay
CREATE TRIGGER trg_SafeGuard_Director
ON NHANVIEN
FOR DELETE, UPDATE
AS
BEGIN
    IF EXISTS (SELECT * FROM deleted WHERE MACV = 'CV09')
    BEGIN
        DECLARE @RemainingDirector INT;
        SELECT @RemainingDirector = COUNT(*) 
        FROM NHANVIEN 
        WHERE MACV = 'CV09';

        IF @RemainingDirector < 1
        BEGIN
            PRINT N'LỖI: Không thể xóa hoặc giáng chức Giám đốc cuối cùng của hệ thống!';
            ROLLBACK TRANSACTION;
        END
    END
END;
GO
-- 3. Function: Kiểm tra quyền Admin
CREATE FUNCTION fn_CheckAdminPermission (@MaNV CHAR(10))
RETURNS BIT -- Trả về 1 (True) nếu là Admin, 0 (False) nếu không
AS
BEGIN
    DECLARE @MaCV CHAR(10);
    DECLARE @IsAdmin BIT = 0;

    SELECT @MaCV = MACV FROM NHANVIEN WHERE MANV = @MaNV;
    -- Quy định: CV09 (Giám đốc) và CV05 (Quản lý cấp cao) là Admin
    IF @MaCV IN ('CV09', 'CV05')
    BEGIN
        SET @IsAdmin = 1;
    END
    RETURN @IsAdmin;
END;
GO
-- 4. Cursor: Cập nhật trạng thái chuyến bay
CREATE PROCEDURE sp_UpdateFlightStatus_Cursor
AS
BEGIN
    DECLARE @MaCB CHAR(10);
    DECLARE @GioCatCanh DATETIME;
    DECLARE @GioHaCanh DATETIME;
    DECLARE @TrangThaiMoi NVARCHAR(50);
    DECLARE @Count INT = 0;
   
    DECLARE cur_FlightStatus CURSOR FOR
    SELECT C.MACB, L.GIOCATCANH, L.GIOHACANH
    FROM CHUYENBAY C
    JOIN LOTRINH L ON C.MACB = L.MACB
    WHERE C.TRANGTHAI NOT IN (N'Hủy', N'Đã hạ cánh');
    OPEN cur_FlightStatus;
    FETCH NEXT FROM cur_FlightStatus INTO @MaCB, @GioCatCanh, @GioHaCanh;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @TrangThaiMoi = NULL;
        IF GETDATE() > @GioHaCanh
            SET @TrangThaiMoi = N'Đã hạ cánh';
        ELSE IF GETDATE() >= @GioCatCanh AND GETDATE() <= @GioHaCanh
            SET @TrangThaiMoi = N'Đang bay';
        IF @TrangThaiMoi IS NOT NULL
        BEGIN
            UPDATE CHUYENBAY 
            SET TRANGTHAI = @TrangThaiMoi 
            WHERE MACB = @MaCB;        
            SET @Count = @Count + 1;
        END
        FETCH NEXT FROM cur_FlightStatus INTO @MaCB, @GioCatCanh, @GioHaCanh;
    END

    CLOSE cur_FlightStatus;
    DEALLOCATE cur_FlightStatus;

    SELECT @Count AS RowsAffected;
END;
GO
-- 5. Proc: Xóa nhân viên an toàn
CREATE PROCEDURE sp_DeleteEmployee_SafeTransaction
    @MaNVCuaBan CHAR(10), -- Nhân viên bị xóa
    @MaNVNhanBanGiao CHAR(10) -- Nhân viên nhận (Thường là Admin thực hiện xóa)
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        IF @MaNVCuaBan = @MaNVNhanBanGiao
        BEGIN
            RAISERROR(N'Không thể xóa chính mình!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        UPDATE VEMAYBAY 
        SET MANV = @MaNVNhanBanGiao 
        WHERE MANV = @MaNVCuaBan;
        UPDATE PHIEUDATVE 
        SET MANV = @MaNVNhanBanGiao 
        WHERE MANV = @MaNVCuaBan;
        DELETE FROM NHANVIEN WHERE MANV = @MaNVCuaBan;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(MAX) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO
-- ======================================================
-- CHỨC NĂNG THANH TOÁN
-- ======================================================

-- 1. Proc: Xác nhận thanh toán giỏ hàng
CREATE PROCEDURE SP_ThanhToanGioHang
    @MAGH CHAR(10)
AS
BEGIN
    UPDATE GIOHANG
    SET TRANGTHAI = N'Đã Thanh Toán'
    WHERE MAGH = @MAGH;
END
GO
-- 2. Function: Tính tổng tiền trong giỏ hàng
CREATE FUNCTION FN_TinhTongTien (@MaGH CHAR(10), @MaCB CHAR(10))
RETURNS MONEY
AS
BEGIN
    DECLARE @Tong MONEY;

    SELECT @Tong = SUM(ISNULL(GIATIEN, 0))
    FROM GIOHANG_CHITIET
    WHERE MAGH = @MaGH AND MACB = @MaCB;

    RETURN @Tong;
END;
GO
-- 3. Proc: Dọn dẹp vé/giỏ hàng hết hạn
CREATE PROCEDURE sp_DonVeHetHan
AS
BEGIN
    BEGIN TRANSACTION;

    -- Xóa ghế giữ trong giỏ đã hết hạn
    DELETE FROM GIOHANG_CHITIET
    WHERE THOIGIANGIU < GETDATE();

    -- Đánh dấu giỏ hàng hết hạn
    UPDATE GIOHANG
    SET TRANGTHAI = N'Đã hết hạn'
    WHERE TRANGTHAI = N'Đang chọn'
      AND NGAYTAO < DATEADD(MINUTE, -15, GETDATE());

    COMMIT TRANSACTION;
END;
GO
-- 4. Trigger: Kiểm tra tuổi hành khách (> 2 tuổi)
CREATE TRIGGER trg_CheckTuoiHanhKhach
ON GIOHANG_HANHKHACH
FOR INSERT
AS
BEGIN
    IF EXISTS (
        SELECT *
        FROM inserted
        WHERE DATEDIFF(YEAR, NGAYSINH, GETDATE()) < 2
    )
    BEGIN
        RAISERROR(N'Hành khách phải ít nhất 2 tuổi!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO
-- 5. Cursor: Tạo phiếu đặt vé từ giỏ hàng đã thanh toán
CREATE PROCEDURE sp_CursorTaoPhieuDatVe
AS
BEGIN
    DECLARE @MAGH CHAR(10), @MAKH CHAR(10), @NewMaPhieu CHAR(10);

    DECLARE cur CURSOR FOR
        SELECT MAGH, MAKH
        FROM GIOHANG
        WHERE TRANGTHAI = N'Đã thanh toán'
          AND MAGH NOT IN (SELECT MAGH FROM PHIEUDATVE);

    OPEN cur;
    FETCH NEXT FROM cur INTO @MAGH, @MAKH;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Tạo mã phiếu đơn giản
        SET @NewMaPhieu = 'PD' + RIGHT('0000' + CAST(ABS(CHECKSUM(NEWID())) % 9999 AS VARCHAR(10)), 4);

        INSERT INTO PHIEUDATVE (MAPHIEU, NGLAP, MANV, MAKH, TRANGTHAI, MAGH)
        VALUES (@NewMaPhieu, GETDATE(), 'NV01', @MAKH, N'Đã thanh toán', @MAGH);

        FETCH NEXT FROM cur INTO @MAGH, @MAKH;
    END

    CLOSE cur;
    DEALLOCATE cur;
END;
GO
-- ======================================================
-- CHỨC NĂNG ĐẶT VÉ
-- ======================================================
--1. TRIGGER – Cập nhật số ghế còn lại
CREATE TRIGGER trg_CapNhatSoGheCon
ON CHITIETVE
AFTER INSERT
AS
BEGIN
    DECLARE @MaCB CHAR(10), @NgayDat DATE, @Tien MONEY;

    SELECT 
        @MaCB = V.MACB,
        @NgayDat = I.NGAYDAT,
        @Tien = I.GIATIEN
    FROM INSERTED I
    JOIN VEMAYBAY V ON I.MAVE = V.MAVE;

    -- Nếu đã tồn tại thống kê → cập nhật
    IF EXISTS (
        SELECT 1 FROM THONGKE_DOANHTHU 
        WHERE MACB = @MaCB AND NGAY = @NgayDat
    )
    BEGIN
        UPDATE THONGKE_DOANHTHU
        SET 
            SOLUONGVE = SOLUONGVE + 1,
            TONGDOANHTHU = TONGDOANHTHU + @Tien
        WHERE MACB = @MaCB AND NGAY = @NgayDat;
    END
    ELSE
    BEGIN
        INSERT INTO THONGKE_DOANHTHU(MACB, NGAY, SOLUONGVE, TONGDOANHTHU)
        VALUES (@MaCB, @NgayDat, 1, @Tien);
    END
END;
GO
--2. STORED PROCEDURE – Đặt vé cho khách hàng
CREATE PROCEDURE sp_DatVe
    @MaKH CHAR(10),
    @MaNV CHAR(10),
    @MAGH CHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        
        -- Tạo mã phiếu ngẫu nhiên
        DECLARE @MaPhieu CHAR(10) = 
            'PDV' + RIGHT(CAST(ABS(CHECKSUM(NEWID())) AS VARCHAR(10)), 6);

        -- Thêm phiếu đặt vé
        INSERT INTO PHIEUDATVE(MAPHIEU, NGLAP, MANV, MAKH, TRANGTHAI, MAGH)
        VALUES (@MaPhieu, GETDATE(), @MaNV, @MaKH, N'Đã đặt', @MAGH);

        -- Các biến cho CURSOR
        DECLARE @MAHK CHAR(20), 
                @MAGHE CHAR(10), 
                @MACB CHAR(10), 
                @GIATIEN MONEY, 
                @MAHG CHAR(10), 
                @MaVe CHAR(10),
                @TenHang NVARCHAR(20);

        -------------------------
        -- KHAI BÁO CURSOR
        -------------------------
        DECLARE cur CURSOR LOCAL FOR
            SELECT ghh.MAHK, g.MAGHE, ghh.MACB, ghh.HANGGHE
            FROM GIOHANG_HANHKHACH ghh
            JOIN GHE g ON g.TENGHE = ghh.SOGHE
            WHERE ghh.MAGH = @MAGH;

        OPEN cur;
        FETCH NEXT FROM cur INTO @MAHK, @MAGHE, @MACB, @TenHang;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Lấy MAHG và giá vé
            SELECT @MAHG = MAHG, @GIATIEN = GIA_COSO
            FROM HANGGHE_GIA
            WHERE MACB = @MACB AND HANGGHE = @TenHang;

            IF @MAHG IS NULL
            BEGIN
                RAISERROR(N'Hạng ghế không tồn tại trong HANGGHE_GIA', 16, 1);
                RETURN;
            END

            -- Sinh mã vé
            SET @MaVe = 'VE' + RIGHT(CAST(ABS(CHECKSUM(NEWID())) AS VARCHAR(10)), 6);

            -- Thêm vé máy bay
            INSERT INTO VEMAYBAY(MAVE, MAGHE, MAHG, GIAVE, MACB, MANV)
            VALUES (@MaVe, @MAGHE, @MAHG, @GIATIEN, @MACB, @MaNV);

            -- Thêm chi tiết vé
            INSERT INTO CHITIETVE(MAVE, MAPHIEU, NGAYDAT, GIATIEN)
            VALUES (@MaVe, @MaPhieu, GETDATE(), @GIATIEN);

            FETCH NEXT FROM cur INTO @MAHK, @MAGHE, @MACB, @TenHang;
        END;

        CLOSE cur;
        DEALLOCATE cur;

    END TRY

    BEGIN CATCH
        -- Nếu cursor còn mở thì đóng
        IF CURSOR_STATUS('local', 'cur') >= 0
        BEGIN
            CLOSE cur;
            DEALLOCATE cur;
        END

        PRINT(ERROR_MESSAGE());
        RAISERROR(N'Lỗi trong sp_DatVe', 16, 1);
        RETURN;
    END CATCH
END;
GO
--3. FUNCTION – Tính tổng tiền khách hàng
CREATE FUNCTION fn_TongTien_KhachHang(@MaKH CHAR(10))
RETURNS MONEY
AS
BEGIN
    DECLARE @Tong MONEY;

    SELECT @Tong = SUM(C.GIATIEN)
    FROM CHITIETVE C
    JOIN PHIEUDATVE P ON C.MAPHIEU = P.MAPHIEU
    WHERE P.MAKH = @MaKH;

    RETURN ISNULL(@Tong, 0);
END;
GO
--4. CURSOR – Duyệt danh sách khách hàng
DECLARE @MaKH CHAR(10), @Tong MONEY;

DECLARE cur_KH CURSOR FOR
    SELECT DISTINCT MAKH FROM PHIEUDATVE;

OPEN cur_KH;
FETCH NEXT FROM cur_KH INTO @MaKH;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @Tong = dbo.fn_TongTien_KhachHang(@MaKH);
    PRINT N'Khách hàng: ' + @MaKH + N' - Tổng tiền đã chi: ' + CAST(@Tong AS NVARCHAR(20));

    FETCH NEXT FROM cur_KH INTO @MaKH;
END

CLOSE cur_KH;
DEALLOCATE cur_KH;
--5. TRANSACTION – Đảm bảo toàn vẹn khi đặt vé
BEGIN TRY
    BEGIN TRAN;

    EXEC sp_DatVe 'KH01', 'NV01', 'GH01';

    COMMIT TRAN;
    PRINT N'Đặt vé hoàn tất!';
END TRY
BEGIN CATCH
    ROLLBACK TRAN;
    PRINT N'Lỗi khi đặt vé';
    PRINT ERROR_MESSAGE();
END CATCH;
GO


-- ======================================================
-- CHỨC NĂNG THỐNG KÊ
-- ======================================================

-- ======================================================
-- 3.2.1. TRIGGER – Tự động cập nhật doanh thu
-- ======================================================
-- Mục đích: Tự động cập nhật bảng THONGKE_DOANHTHU mỗi khi có vé mới được thêm vào bảng CHITIETVE
-- Mô tả: Trigger này tự động chạy khi có INSERT vào bảng CHITIETVE.
--        Nó lấy mã chuyến bay, ngày đặt vé, tổng tiền và số lượng vé từ dữ liệu mới thêm.
--        Nếu ngày và chuyến bay đó đã có trong bảng thống kê, hệ thống cập nhật tổng doanh thu;
--        nếu chưa có, thêm mới bản ghi thống kê.
CREATE TRIGGER trg_CapNhatDoanhThu
ON CHITIETVE
FOR INSERT
AS
BEGIN
    DECLARE 
        @MaCB CHAR(10),
        @Ngay DATE,
        @TongTien MONEY,
        @SoLuong INT;
        
    SELECT 
        @MaCB = V.MACB,
        @Ngay = CAST(I.NGAYDAT AS DATE),
        @TongTien = SUM(I.GIATIEN),
        @SoLuong = COUNT(I.MAVE)
    FROM INSERTED I
    JOIN VEMAYBAY V ON I.MAVE = V.MAVE
    GROUP BY V.MACB, CAST(I.NGAYDAT AS DATE);

    IF EXISTS (SELECT 1 FROM THONGKE_DOANHTHU WHERE MACB = @MaCB AND NGAY = @Ngay)
    BEGIN
        UPDATE THONGKE_DOANHTHU
        SET 
            TONGDOANHTHU = TONGDOANHTHU + @TongTien,
            SOLUONGVE = SOLUONGVE + @SoLuong
        WHERE MACB = @MaCB AND NGAY = @Ngay;
    END
    ELSE
    BEGIN
        INSERT INTO THONGKE_DOANHTHU (MACB, NGAY, TONGDOANHTHU, SOLUONGVE)
        VALUES (@MaCB, @Ngay, @TongTien, @SoLuong);
    END
END;
GO


-- ======================================================
-- CHUẨN BỊ: Tạo ghế mới cho test (tránh lỗi FK)
-- ======================================================
PRINT N'Chuẩn bị dữ liệu test...';
-- Tạo 2 ghế mới cho máy bay MB01
IF NOT EXISTS (SELECT * FROM GHE WHERE MAGHE = 'GH_T01')
    INSERT INTO GHE (MAGHE, MAMB, TENGHE, HANGGHE)
    VALUES ('GH_T01', 'MB01', '99A', N'Phổ thông');
IF NOT EXISTS (SELECT * FROM GHE WHERE MAGHE = 'GH_T02')
    INSERT INTO GHE (MAGHE, MAMB, TENGHE, HANGGHE)
    VALUES ('GH_T02', 'MB01', '99B', N'Phổ thông');
PRINT N'Đã tạo ghế test';
PRINT '';

--PRINT N'TEST 1: TRIGGER tự động cập nhật doanh thu';

-- Xem dữ liệu ban đầu
PRINT N'Dữ liệu THONGKE_DOANHTHU trước khi thêm vé:';
SELECT * FROM THONGKE_DOANHTHU WHERE NGAY = '2026-01-15';
-- Thêm vé vào VEMAYBAY (sử dụng ghế vừa tạo)
INSERT INTO VEMAYBAY (MAVE, MAGHE, MAHG, GIAVE, MACB, MANV)
VALUES ('VE_TEST1', 'GH_T01', 'HG01', 3000000, 'CB01', 'NV01');
-- Thêm chi tiết vé → Trigger tự động chạy
INSERT INTO CHITIETVE (MAVE, MAPHIEU, NGAYDAT, GIATIEN)
VALUES ('VE_TEST1', 'PD01', '2026-01-15', 3000000);
PRINT N'';
PRINT N'Dữ liệu THONGKE_DOANHTHU sau khi thêm vé đầu tiên:';
SELECT * FROM THONGKE_DOANHTHU WHERE NGAY = '2026-01-15';
-- Thêm vé thứ 2 cùng ngày để test UPDATE
INSERT INTO VEMAYBAY (MAVE, MAGHE, MAHG, GIAVE, MACB, MANV)
VALUES ('VE_TEST2', 'GH_T02', 'HG01', 2500000, 'CB01', 'NV01');
INSERT INTO CHITIETVE (MAVE, MAPHIEU, NGAYDAT, GIATIEN)
VALUES ('VE_TEST2', 'PD01', '2026-01-15', 2500000);
PRINT N'';
PRINT N'Sau khi thêm vé thứ 2 (test UPDATE):';
SELECT * FROM THONGKE_DOANHTHU WHERE NGAY = '2026-01-15';
PRINT N'→ Kết quả mong đợi: TONGDOANHTHU = 5500000, SOLUONGVE = 2';


-- ======================================================
-- 3.2.2. STORED PROCEDURE – Tính doanh thu theo tháng
-- ======================================================
-- Mục đích: Tính tổng doanh thu trong một tháng cụ thể
-- Mô tả: Procedure này nhận vào tháng và năm, sau đó trả về tổng doanh thu thông qua biến OUTPUT
CREATE PROCEDURE sp_TinhTongDoanhThu_Thang
    @Thang INT,
    @Nam INT,
    @TongDoanhThu MONEY OUTPUT
AS
BEGIN
    SELECT @TongDoanhThu = ISNULL(SUM(CT.GIATIEN), 0)
    FROM CHITIETVE CT
    WHERE MONTH(CT.NGAYDAT) = @Thang 
      AND YEAR(CT.NGAYDAT) = @Nam;
END;
GO

--PRINT N'TEST 2: PROCEDURE tính doanh thu theo tháng';
--PRINT N'--------------------------------------------';
-- Test với tháng 11/2025 (có dữ liệu sẵn)
DECLARE @DoanhThu1 MONEY;
EXEC sp_TinhTongDoanhThu_Thang 
    @Thang = 11, 
    @Nam = 2025, 
    @TongDoanhThu = @DoanhThu1 OUTPUT;
PRINT N'Doanh thu tháng 11/2025: ' + CAST(ISNULL(@DoanhThu1, 0) AS NVARCHAR(20)) + N' VND';
-- Test với tháng 1/2026 (vừa tạo ở trên)
DECLARE @DoanhThu2 MONEY;
EXEC sp_TinhTongDoanhThu_Thang 
    @Thang = 1, 
    @Nam = 2026, 
    @TongDoanhThu = @DoanhThu2 OUTPUT;
PRINT N'Doanh thu tháng 01/2026: ' + CAST(ISNULL(@DoanhThu2, 0) AS NVARCHAR(20)) + N' VND';
-- Test với tháng không có dữ liệu
DECLARE @DoanhThu3 MONEY;
EXEC sp_TinhTongDoanhThu_Thang 
    @Thang = 12, 
    @Nam = 2026, 
    @TongDoanhThu = @DoanhThu3 OUTPUT;
PRINT N'Doanh thu tháng 12/2026: ' + CAST(ISNULL(@DoanhThu3, 0) AS NVARCHAR(20)) + N' VND (không có dữ liệu)';


-- ======================================================
-- 3.2.3. FUNCTION – Thống kê số lượng khách hàng theo quốc gia
-- ======================================================
-- Mục đích: Thống kê số lượng khách hàng theo từng quốc gia phục vụ cho mục đích phân tích thị trường
-- Mô tả: Function trả về bảng gồm hai cột: QUOCGIA và SOKHACH
--        Có thể sử dụng trực tiếp trong câu lệnh SELECT * FROM fn_ThongKeKhachTheoQuocGia()
CREATE FUNCTION fn_ThongKeKhachTheoQuocGia()
RETURNS TABLE
AS
RETURN
(
    SELECT 
        KH.QUOCGIA, 
        COUNT(KH.MAKH) AS SOKHACH
    FROM KHACHHANG KH
    GROUP BY KH.QUOCGIA
);
GO

SELECT * FROM fn_ThongKeKhachTheoQuocGia()
-- Chuyển 1 khách Việt Nam sang Mỹ
UPDATE KHACHHANG
SET QUOCGIA = N'Mỹ'
WHERE MAKH = 'KH09';

-- Thêm 2 khách Nhật Bản mới
INSERT INTO KHACHHANG (MAKH, TENKH, EMAIL, MATKHAU, SDT, DIACHI, GTINH, NGSINH, QUOCGIA)
VALUES 
('KH_JP1', N'Tanaka Yuki', 'yuki@jp.com', 'pass123', '0900000011', N'Tokyo', N'Nam', '1990-01-01', N'Nhật Bản'),
('KH_JP2', N'Sakura Hana', 'sakura@jp.com', 'pass123', '0900000012', N'Osaka', N'Nữ', '1992-05-15', N'Nhật Bản');
-- Xem lại
SELECT * FROM fn_ThongKeKhachTheoQuocGia() ORDER BY SOKHACH DESC;

-- ======================================================
-- 3.2.4. CURSOR – Thống kê doanh thu từng chuyến bay
-- ======================================================
-- Mục đích: Thống kê doanh thu của từng chuyến bay bằng cách duyệt qua toàn bộ các chuyến 
--           trong bảng CHUYENBAY và tính tổng tiền vé tương ứng
-- Mô tả: Đoạn mã sử dụng CURSOR để lần lượt lấy từng mã chuyến bay (MACB) trong bảng CHUYENBAY,
--        sau đó tính tổng doanh thu (tổng GIATIEN) của các vé thuộc chuyến bay đó từ bảng CHITIETVE.
--        Nếu chuyến bay chưa có vé, doanh thu được gán bằng 0.
--        Kết quả được in trực tiếp ra màn hình bằng lệnh PRINT.
CREATE PROCEDURE sp_ThongKeDoanhThuTheoChuyen
AS
BEGIN
    -- Tạo bảng tạm để lưu kết quả
    CREATE TABLE #TempDoanhThu (
        MaChuyenBay CHAR(10),
        TongDoanhThu MONEY
    );
    DECLARE @MaCB CHAR(10);
    DECLARE @TongDoanhThu MONEY;
    
    DECLARE cur_ThongKeDoanhThu CURSOR FOR
        SELECT MACB
        FROM CHUYENBAY;
    
    OPEN cur_ThongKeDoanhThu;
    FETCH NEXT FROM cur_ThongKeDoanhThu INTO @MaCB;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @TongDoanhThu = ISNULL(SUM(CT.GIATIEN), 0)
        FROM CHITIETVE CT
        JOIN VEMAYBAY V ON CT.MAVE = V.MAVE
        WHERE V.MACB = @MaCB;
        
        IF @TongDoanhThu IS NULL
            SET @TongDoanhThu = 0;
        
        -- Lưu vào bảng tạm thay vì PRINT
        INSERT INTO #TempDoanhThu (MaChuyenBay, TongDoanhThu)
        VALUES (@MaCB, @TongDoanhThu);
        
        FETCH NEXT FROM cur_ThongKeDoanhThu INTO @MaCB;
    END;
    
    CLOSE cur_ThongKeDoanhThu;
    DEALLOCATE cur_ThongKeDoanhThu;
    
    -- Trả về kết quả
    SELECT MaChuyenBay, TongDoanhThu
    FROM #TempDoanhThu
    ORDER BY TongDoanhThu DESC;
    
    -- Xóa bảng tạm
    DROP TABLE #TempDoanhThu;
END;
GO

--PRINT N'TEST 6: PROCEDURE thống kê doanh thu theo chuyến bay (dùng CURSOR)';
EXEC sp_ThongKeDoanhThuTheoChuyen;

-- Tạo ghế test nếu chưa có
IF NOT EXISTS (SELECT * FROM GHE WHERE MAGHE = 'GH_TEST1')
    INSERT INTO GHE (MAGHE, MAMB, TENGHE, HANGGHE)
    VALUES ('GH_TEST1', 'MB01', 'T1A', N'Phổ thông');
IF NOT EXISTS (SELECT * FROM GHE WHERE MAGHE = 'GH_TEST2')
    INSERT INTO GHE (MAGHE, MAMB, TENGHE, HANGGHE)
    VALUES ('GH_TEST2', 'MB01', 'T1B', N'Phổ thông');
IF NOT EXISTS (SELECT * FROM GHE WHERE MAGHE = 'GH_TEST3')
    INSERT INTO GHE (MAGHE, MAMB, TENGHE, HANGGHE)
    VALUES ('GH_TEST3', 'MB04', 'T2A', N'Phổ thông');


-- Thêm vé cho CB01 (3,000,000 VND)
IF NOT EXISTS (SELECT * FROM VEMAYBAY WHERE MAVE = 'VE_CB01_1')
BEGIN
    INSERT INTO VEMAYBAY (MAVE, MAGHE, MAHG, GIAVE, MACB, MANV)
    VALUES ('VE_CB01_1', 'GH_TEST1', 'HG01', 3000000, 'CB01', 'NV01');
    
    INSERT INTO CHITIETVE (MAVE, MAPHIEU, NGAYDAT, GIATIEN)
    VALUES ('VE_CB01_1', 'PD01', '2026-01-15', 3000000);
    
    PRINT N'Đã thêm vé VE_CB01_1: 3,000,000 VND cho CB01';
END
-- Thêm vé thứ 2 cho CB01 (2,500,000 VND)
IF NOT EXISTS (SELECT * FROM VEMAYBAY WHERE MAVE = 'VE_CB01_2')
BEGIN
    INSERT INTO VEMAYBAY (MAVE, MAGHE, MAHG, GIAVE, MACB, MANV)
    VALUES ('VE_CB01_2', 'GH_TEST2', 'HG01', 2500000, 'CB01', 'NV01');
    
    INSERT INTO CHITIETVE (MAVE, MAPHIEU, NGAYDAT, GIATIEN)
    VALUES ('VE_CB01_2', 'PD01', '2026-01-16', 2500000);
    
    PRINT N'Đã thêm vé VE_CB01_2: 2,500,000 VND cho CB01';
END
-- Thêm vé cho CB04 (4,000,000 VND)
IF NOT EXISTS (SELECT * FROM VEMAYBAY WHERE MAVE = 'VE_CB04_1')
BEGIN
    INSERT INTO VEMAYBAY (MAVE, MAGHE, MAHG, GIAVE, MACB, MANV)
    VALUES ('VE_CB04_1', 'GH_TEST3', 'HG06', 4000000, 'CB04', 'NV01');
    
    INSERT INTO CHITIETVE (MAVE, MAPHIEU, NGAYDAT, GIATIEN)
    VALUES ('VE_CB04_1', 'PD02', '2026-01-17', 4000000);
    
    PRINT N'Đã thêm vé VE_CB04_1: 4,000,000 VND cho CB04';
END



-- Xóa chi tiết vé
DELETE FROM CHITIETVE WHERE MAVE IN ('VE_CB01_1', 'VE_CB01_2', 'VE_CB04_1');
PRINT N'Đã xóa CHITIETVE';
-- Xóa vé máy bay
DELETE FROM VEMAYBAY WHERE MAVE IN ('VE_CB01_1', 'VE_CB01_2', 'VE_CB04_1');
PRINT N'Đã xóa VEMAYBAY';
-- Xóa ghế test
DELETE FROM GHE WHERE MAGHE IN ('GH_TEST1', 'GH_TEST2', 'GH_TEST3');
PRINT N'Đã xóa GHE test';
-- Xóa thống kê
DELETE FROM THONGKE_DOANHTHU WHERE NGAY >= '2026-01-15';
PRINT N'Đã xóa THONGKE_DOANHTHU';
PRINT '';
PRINT N'Doanh thu sau khi xóa:';
EXEC sp_ThongKeDoanhThuTheoChuyen;



-- ======================================================
-- STORED PROCEDURE: Xuất dữ liệu chuyến bay ra Excel
-- ======================================================
CREATE PROCEDURE sp_ExportChuyenBay
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        CB.MACB AS MaChuyenBay,
        MB.TENMB AS TenMayBay,
        MB.HANG AS Hang,
        CB.TRANGTHAI AS TrangThai,
        SB1.THANHPHO AS SanBayDi,
        SB2.THANHPHO AS SanBayDen,
        LT.GIOCATCANH AS GioCatCanh,
        LT.GIOHACANH AS GioHaCanh
    FROM CHUYENBAY CB
    INNER JOIN MAYBAY MB ON CB.MAMB = MB.MAMB
    LEFT JOIN LOTRINH LT ON CB.MACB = LT.MACB
    LEFT JOIN SANBAY SB1 ON LT.SBDI = SB1.MASB
    LEFT JOIN SANBAY SB2 ON LT.SBDEN = SB2.MASB
    ORDER BY LT.GIOCATCANH DESC;
END;
GO

-- ======================================================
-- STORED PROCEDURE: Thống kê số lần bay của khách hàng
-- ======================================================
CREATE PROCEDURE sp_ThongKeSoLanBayKhachHang
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        KH.MAKH,
        KH.TENKH,
        KH.EMAIL,
        KH.SDT,
        KH.QUOCGIA,
        dbo.FN_SoLanBayKhachHang(KH.MAKH) AS SoLanBay
    FROM KHACHHANG KH
    ORDER BY dbo.FN_SoLanBayKhachHang(KH.MAKH) DESC;
END;
GO



--====================================================================================
--====================================================================================
 --1. Trigger:  tạo ra nhằm ngăn chặn việc check-in trùng cho cùng một vé
CREATE TRIGGER TRG_KiemTraCheckIn
ON CHECKIN
FOR INSERT
AS
BEGIN
    DECLARE @MAVE CHAR(5);

    SELECT @MAVE = MAVE FROM INSERTED;

    IF EXISTS (SELECT * FROM CHECKIN WHERE MAVE = @MAVE AND MACHECKIN NOT IN (SELECT MACHECKIN FROM INSERTED))
    BEGIN
        PRINT (N'Vé này đã được check-in trước đó!');
        ROLLBACK TRANSACTION;
    END
END;
GO
--2. Stored Procedure: Kiểm tra hiện trạng thông qua giờ cất cánh và giờ hạ cánh
CREATE PROCEDURE sp_KiemTraTrangThaiChuyenBay
    @MACB CHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @GioCatCanh DATETIME,
            @GioHaCanh DATETIME,
            @Now DATETIME = GETDATE();
    
    SELECT 
        @GioCatCanh = GIOCATCANH,
        @GioHaCanh = GIOHACANH
    FROM LOTRINH
    WHERE MACB = @MACB;
   
    IF (@GioCatCanh IS NULL OR @GioHaCanh IS NULL)
    BEGIN
        SELECT N'KHÔNG TỒN TẠI CHUYẾN BAY' AS TrangThai;
        RETURN;
    END
    
    SELECT
        CASE
            WHEN @Now < @GioCatCanh THEN N'CHƯA CẤT CÁNH'
            WHEN @Now >= @GioCatCanh AND @Now <= @GioHaCanh THEN N'ĐANG BAY'
            ELSE N'ĐÃ HẠ CÁNH'
        END AS TrangThai;
END;
GO
--3. Function: Tính tổng số vé mà một khách hàng đã đặt trong hệ thống.
CREATE FUNCTION FN_SoLanBayKhachHang (@MAKH CHAR(5))
RETURNS INT
AS
BEGIN
    DECLARE @SOLAN INT;
    
    SELECT @SOLAN = COUNT(CT.MAVE)
    FROM CHITIETVE AS CT
    JOIN PHIEUDATVE AS P 
        ON CT.MAPHIEU = P.MAPHIEU
    WHERE P.MAKH = @MAKH;
    
    RETURN ISNULL(@SOLAN, 0);
END;
GO


