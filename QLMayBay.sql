USE [master]
GO
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'QUANLYMAYBAY')
BEGIN
    ALTER DATABASE [QUANLYMAYBAY] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [QUANLYMAYBAY];
END
GO
CREATE DATABASE [QUANLYMAYBAY]
GO
USE [QUANLYMAYBAY]
GO

-- ======================================================
-- PHẦN 1: ĐỊNH NGHĨA CÁC HÀM UDF (USER-DEFINED FUNCTIONS)
-- ======================================================

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- 1. Kiểm tra quyền Admin của nhân viên
CREATE FUNCTION [dbo].[fn_CheckAdminPermission] (@MaNV CHAR(10))
RETURNS BIT
AS
BEGIN
    DECLARE @MaCV CHAR(10);
    DECLARE @IsAdmin BIT = 0;
    SELECT @MaCV = MACV FROM NHANVIEN WHERE MANV = @MaNV;
    IF @MaCV IN ('CV09', 'CV05')
    BEGIN
        SET @IsAdmin = 1;
    END
    RETURN @IsAdmin;
END;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- 2. Tính tổng số vé mà một khách hàng đã đặt
CREATE FUNCTION [dbo].[FN_SoLanBayKhachHang] (@MAKH CHAR(5))
RETURNS INT
AS
BEGIN
    DECLARE @SOLAN INT;
    SELECT @SOLAN = COUNT(CT.MAVE)
    FROM CHITIETVE AS CT
    JOIN PHIEUDATVE AS P ON CT.MAPHIEU = P.MAPHIEU
    WHERE P.MAKH = @MAKH;
    RETURN ISNULL(@SOLAN, 0);
END;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- 3. Tính tổng tiền trong một chi tiết chuyến bay của giỏ hàng
CREATE FUNCTION [dbo].[FN_TinhTongTien] (@MaGH CHAR(10), @MaCB CHAR(10))
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

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- 4. Tính tổng tiền tích lũy khách hàng đã chi trả
CREATE FUNCTION [dbo].[fn_TongTien_KhachHang](@MaKH CHAR(10))
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

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- 5. Thống kê số lượng khách hàng phân bổ theo quốc gia
CREATE FUNCTION [dbo].[fn_ThongKeKhachTheoQuocGia] ()
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

-- ======================================================
-- PHẦN 2: KHỞI TẠO CẤU TRÚC CÁC BẢNG (DDL)
-- ======================================================

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[KHACHHANG](
	[MAKH] [char](10) NOT NULL,
	[TENKH] [nvarchar](50) NULL,
	[EMAIL] [varchar](100) NULL,
	[MATKHAU] [varchar](50) NULL,
	[SDT] [varchar](20) NULL,
	[DIACHI] [nvarchar](100) NULL,
	[GTINH] [nvarchar](3) NULL,
	[NGSINH] [date] NULL,
	[QUOCGIA] [nvarchar](50) NULL,
 CONSTRAINT [PK_KH] PRIMARY KEY CLUSTERED ([MAKH] ASC)
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[CAUHINH_GHE](
	[MACG] [char](10) NOT NULL,
	[MAMB] [char](10) NOT NULL,
	[HANGGHE] [nvarchar](20) NOT NULL,
	[SOLUONG] [int] NULL,
 CONSTRAINT [PK_CG] PRIMARY KEY CLUSTERED ([MACG] ASC)
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[CHECKIN](
	[MACHECKIN] [char](10) NOT NULL,
	[MAVE] [char](10) NOT NULL,
	[MAKH] [char](10) NOT NULL,
	[MACB] [char](10) NOT NULL,
	[TRANGTHAI] [nvarchar](30) NULL,
	[THOIGIAN_CHECKIN] [datetime] NULL,
 CONSTRAINT [PK_CI] PRIMARY KEY CLUSTERED ([MACHECKIN] ASC)
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[CHITIETVE](
	[MAVE] [char](10) NOT NULL,
	[MAPHIEU] [char](10) NOT NULL,
	[NGAYDAT] [date] NULL,
	[GIATIEN] [money] NULL,
 CONSTRAINT [PK_CTV] PRIMARY KEY CLUSTERED ([MAVE] ASC, [MAPHIEU] ASC)
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[CHUCVU](
	[MACV] [char](10) NOT NULL,
	[TENCV] [nvarchar](50) NULL,
 CONSTRAINT [PK_CV] PRIMARY KEY CLUSTERED ([MACV] ASC)
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[CHUYENBAY](
	[MACB] [char](10) NOT NULL,
	[TRANGTHAI] [nvarchar](20) NULL,
	[MAMB] [char](10) NULL,
 CONSTRAINT [PK_CB] PRIMARY KEY CLUSTERED ([MACB] ASC)
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[GHE](
	[MAGHE] [char](10) NOT NULL,
	[MAMB] [char](10) NOT NULL,
	[TENGHE] [nvarchar](10) NULL,
	[HANGGHE] [nvarchar](20) NULL,
 CONSTRAINT [PK_GHE] PRIMARY KEY CLUSTERED ([MAGHE] ASC)
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[GIOHANG](
	[MAGH] [char](10) NOT NULL,
	[MAKH] [char](10) NOT NULL,
	[NGAYTAO] [datetime] NULL,
	[TRANGTHAI] [nvarchar](20) NULL,
 CONSTRAINT [PK_GH] PRIMARY KEY CLUSTERED ([MAGH] ASC)
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[GIOHANG_CHITIET](
	[MAGH] [char](10) NOT NULL,
	[MACB] [char](10) NOT NULL,
	[SOLUONG] [int] NULL,
	[GIATIEN] [money] NULL,
	[THOIGIANGIU] [datetime] NULL,
 CONSTRAINT [PK_GHCT] PRIMARY KEY CLUSTERED ([MAGH] ASC, [MACB] ASC)
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[GIOHANG_HANHKHACH](
	[MAHK] [char](20) NOT NULL,
	[SOGHE] [char](10) NOT NULL,
	[MAGH] [char](10) NOT NULL,
	[MACB] [char](10) NOT NULL,
	[HANGGHE] [nvarchar](20) NOT NULL,
	[TENHANHKHACH] [nvarchar](100) NULL,
	[NGAYSINH] [date] NULL,
	[GIOITINH] [nvarchar](3) NULL,
	[EMAIL] [varchar](100) NULL,
	[SDT] [varchar](10) NULL,
	[HANGLY_XACHTAY] [int] NULL,
	[HANHLYKYGUI] [int] NULL,
 CONSTRAINT [PK_GHHK] PRIMARY KEY CLUSTERED ([MAHK] ASC)
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[HANGGHE_GIA](
	[MAHG] [char](10) NOT NULL,
	[MACB] [char](10) NOT NULL,
	[HANGGHE] [nvarchar](20) NULL,
	[GIA_COSO] [money] NULL,
 CONSTRAINT [PK_HGG] PRIMARY KEY CLUSTERED ([MAHG] ASC)
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[HANHLY](
	[MAHL] [char](10) NOT NULL,
	[MAVE] [char](10) NOT NULL,
	[MACB] [char](10) NOT NULL,
	[LOAIHL] [nvarchar](20) NULL,
	[KHOILUONG] [float] NULL,
	[KICHTHUOC] [float] NULL,
 CONSTRAINT [PK_HL] PRIMARY KEY CLUSTERED ([MAHL] ASC)
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[LOTRINH](
	[MALT] [char](10) NOT NULL,
	[MACB] [char](10) NOT NULL,
	[SBDI] [char](10) NOT NULL,
	[SBDEN] [char](10) NOT NULL,
	[GIOCATCANH] [datetime] NOT NULL,
	[GIOHACANH] [datetime] NOT NULL,
 CONSTRAINT [PK_LT] PRIMARY KEY CLUSTERED ([MALT] ASC)
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[MAYBAY](
	[MAMB] [char](10) NOT NULL,
	[TENMB] [nvarchar](50) NULL,
	[HANG] [nvarchar](50) NULL,
	[TONGSOGHE] [int] NULL,
 CONSTRAINT [PK_MB] PRIMARY KEY CLUSTERED ([MAMB] ASC)
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[NHANVIEN](
	[MANV] [char](10) NOT NULL,
	[TENNV] [nvarchar](50) NULL,
	[SDT] [varchar](15) NULL,
	[MACV] [char](10) NULL,
	[MATKHAU] [varchar](50) NULL,
 CONSTRAINT [PK_NV] PRIMARY KEY CLUSTERED ([MANV] ASC)
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[PHIEUDATVE](
	[MAPHIEU] [char](10) NOT NULL,
	[NGLAP] [date] NULL,
	[MANV] [char](10) NULL,
	[MAKH] [char](10) NULL,
	[TRANGTHAI] [nvarchar](30) NULL,
	[MAGH] [char](10) NULL,
 CONSTRAINT [PK_PDV] PRIMARY KEY CLUSTERED ([MAPHIEU] ASC)
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[SANBAY](
	[MASB] [char](10) NOT NULL,
	[TENSB] [nvarchar](50) NULL,
	[THANHPHO] [nvarchar](50) NULL,
 CONSTRAINT [PK_SB] PRIMARY KEY CLUSTERED ([MASB] ASC)
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[THONGKE_DOANHTHU](
	[MACB] [char](10) NOT NULL,
	[NGAY] [date] NOT NULL,
	[TONGDOANHTHU] [money] NULL,
	[SOLUONGVE] [int] NULL,
 CONSTRAINT [PK_TK] PRIMARY KEY CLUSTERED ([MACB] ASC,	[NGAY] ASC)
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[VEMAYBAY](
	[MAVE] [char](10) NOT NULL,
	[MAGHE] [char](10) NOT NULL,
	[MAHG] [char](10) NULL,
	[GIAVE] [money] NULL,
	[MACB] [char](10) NULL,
	[MANV] [char](10) NULL,
 CONSTRAINT [PK_VMB] PRIMARY KEY CLUSTERED ([MAVE] ASC)
) ON [PRIMARY]
GO

-- ======================================================
-- PHẦN 3: CHÈN DỮ LIỆU MẪU CHUẨN (DML) - TỪ QLMAYBAY.SQL
-- ======================================================

-- 1. Chức vụ
INSERT INTO [dbo].[CHUCVU] VALUES ('CV01', N'Nhân viên bán vé'), ('CV02', N'Nhân viên check-in'), ('CV03', N'Tiếp viên trưởng'), ('CV04', N'Phi công cơ trưởng'), ('CV05', N'Quản lý cấp cao'), ('CV06', N'Kỹ thuật viên bảo trì'), ('CV07', N'Nhân viên hành lý'), ('CV08', N'Nhân viên kế toán'), ('CV09', N'Giám đốc sân bay'), ('CV10', N'Nhân viên Marketing');
-- 2. Nhân viên
INSERT INTO [dbo].[NHANVIEN] VALUES ('NV01', N'Nguyễn Văn A', '0901234567', 'CV01', '123456'), ('NV02', N'Lê Thị B', '0902345678', 'CV02', '123456'), ('NV03', N'Trần Văn C', '0903456789', 'CV03', '123456'), ('NV04', N'Phạm Văn D', '0904567890', 'CV04', 'pilot123'), ('NV05', N'Hoàng Thị E', '0905678901', 'CV05', 'admin123'), ('NV06', N'Võ Minh F', '0906789012', 'CV06', 'tech123'), ('NV07', N'Đặng Thị G', '0907890123', 'CV07', 'bag123'), ('NV08', N'Bùi Văn H', '0908901234', 'CV08', 'acc123'), ('NV09', N'Tô Thị I', '0909012345', 'CV09', 'admin123'), ('NV10', N'Lý Văn K', '0900123456', 'CV10', 'mark123');
-- 3. Khách hàng
INSERT INTO [dbo].[KHACHHANG] VALUES ('KH01', N'Nguyễn Minh Khoa', 'khoa@gmail.com', '123456', '0911111111', N'Hà Nội', N'Nam', '1990-05-12', N'Việt Nam'), ('KH02', N'Lê Thanh Hoa', 'hoa@gmail.com', 'hoa2025', '0922222222', N'Hồ Chí Minh', N'Nữ', '1995-07-20', N'Việt Nam'), ('KH03', N'John Smith', 'john@gmail.com', 'johnpass', '0933333333', N'New York', N'Nam', '1988-09-15', N'Mỹ'), ('KH04', N'Nguyễn Văn Nam', 'nam@gmail.com', 'namvip', '0944444444', N'Đà Nẵng', N'Nam', '1992-01-30', N'Việt Nam'), ('KH05', N'Lý Thu Hà', 'ha@gmail.com', 'ha2025', '0955555555', N'Hải Phòng', N'Nữ', '1998-11-25', N'Việt Nam'), ('KH06', N'Trần Đức Tài', 'tai@gmail.com', 'tai123', '0966666666', N'Cần Thơ', N'Nam', '1985-03-10', N'Việt Nam'), ('KH07', N'Mai Hồng Nhung', 'nhung@gmail.com', 'nhungvip', '0977777777', N'Huế', N'Nữ', '1993-08-05', N'Việt Nam'), ('KH08', 'David Lee', 'david@gmail.com', 'davidp', '0988888888', N'Seoul', N'Nam', '1991-12-24', N'Hàn Quốc'), ('KH09', N'Phan Thúy An', 'an@gmail.com', 'anpass', '0999999999', N'Quy Nhơn', N'Nữ', '2000-04-17', N'Việt Nam'), ('KH10', N'Nguyễn Hùng Sơn', 'son@gmail.com', 'sonpass', '0900000000', N'Nha Trang', N'Nam', '1980-06-28', N'Việt Nam');
-- 4. Máy bay
INSERT INTO [dbo].[MAYBAY] VALUES ('MB01', N'Airbus A320', N'Airbus', 180), ('MB02', N'Boeing 737-800', N'Boeing', 150), ('MB03', N'Airbus A321', N'Airbus', 220), ('MB04', N'Boeing 787-9', N'Boeing', 280), ('MB05', N'ATR 72-600', N'ATR', 80), ('MB06', N'Embraer 190', N'Embraer', 100), ('MB07', N'Airbus A350', N'Airbus', 350), ('MB08', N'Boeing 777-300ER', N'Boeing', 380), ('MB09', N'Bombardier CRJ900', N'Bombardier', 90), ('MB10', N'Airbus A330', N'Airbus', 300);
-- 5. Cấu hình ghế
INSERT INTO [dbo].[CAUHINH_GHE] VALUES ('CG01', 'MB01', N'Phổ thông', 170), ('CG02', 'MB01', N'Thương gia', 10), ('CG03', 'MB02', N'Phổ thông', 140), ('CG04', 'MB02', N'Thương gia', 10), ('CG05', 'MB03', N'Phổ thông', 200), ('CG06', 'MB03', N'Thương gia', 20), ('CG07', 'MB04', N'Phổ thông', 250), ('CG08', 'MB04', N'Thương gia', 30), ('CG09', 'MB05', N'Phổ thông', 80), ('CG10', 'MB07', N'Hạng nhất', 10);
-- 6. Sân bay
INSERT INTO [dbo].[SANBAY] VALUES ('SB01', N'Nội Bài', N'Hà Nội'), ('SB02', N'Tân Sơn Nhất', N'Hồ Chí Minh'), ('SB03', N'Đà Nẵng', N'Đà Nẵng'), ('SB04', N'Cam Ranh', N'Khánh Hòa'), ('SB05', N'Cát Bi', N'Hải Phòng'), ('SB06', N'Cần Thơ', N'Cần Thơ'), ('SB07', N'Phú Bài', N'Huế'), ('SB08', N'Phú Quốc', N'Kiên Giang'), ('SB09', N'Vinh', N'Nghệ An'), ('SB10', N'Liên Khương', N'Lâm Đồng');
-- 7. Chuyến bay
INSERT INTO [dbo].[CHUYENBAY] VALUES ('CB01', N'Đang bay', 'MB01'), ('CB02', N'Đang bay', 'MB02'), ('CB03', N'Đang bay', 'MB03'), ('CB04', N'Đang bay', 'MB04'), ('CB05', N'Hủy', 'MB05'), ('CB06', N'Đang bay', 'MB06'), ('CB07', N'Đang bay', 'MB07'), ('CB08', N'Đang bay', 'MB08'), ('CB09', N'Đang bay', 'MB09'), ('CB10', N'Đang bay', 'MB10');
-- 8. Lộ trình
INSERT INTO [dbo].[LOTRINH] VALUES ('LT01', 'CB01', 'SB02', 'SB01', '2025-12-29 08:00:00', '2025-12-29 10:00:00'), ('LT02', 'CB02', 'SB03', 'SB02', '2025-12-29 14:00:00', '2025-12-29 16:30:00'), ('LT03', 'CB03', 'SB01', 'SB03', '2025-12-30 09:00:00', '2025-12-30 11:00:00'), ('LT04', 'CB04', 'SB01', 'SB02', '2025-12-30 11:00:00', '2025-12-30 13:00:00'), ('LT05', 'CB05', 'SB05', 'SB01', '2025-12-31 06:00:00', '2025-12-31 07:30:00'), ('LT06', 'CB06', 'SB03', 'SB06', '2026-01-01 12:00:00', '2026-01-01 13:30:00'), ('LT07', 'CB07', 'SB02', 'SB01', '2026-01-02 15:00:00', '2026-01-02 17:00:00'), ('LT08', 'CB08', 'SB02', 'SB03', '2026-01-03 18:00:00', '2026-01-03 20:30:00'), ('LT09', 'CB09', 'SB07', 'SB02', '2026-01-04 07:30:00', '2026-01-04 09:00:00'), ('LT10', 'CB10', 'SB03', 'SB05', '2026-01-05 10:00:00', '2026-01-05 11:30:00');
-- 9. Ghế
INSERT INTO [dbo].[GHE] VALUES ('GH01','MB01','12A',N'Phổ thông'), ('GH02','MB01','12B',N'Phổ thông'), ('GH03','MB01','01A',N'Thương gia'), ('GH04','MB02','14B',N'Phổ thông'), ('GH05','MB03','15C',N'Phổ thông'), ('GH06','MB04','05D',N'Phổ thông'), ('GH07','MB06','10A',N'Phổ thông'), ('GH08','MB07','01D',N'Hạng nhất'), ('GH09','MB08','20E',N'Phổ thông'), ('GH10','MB09','03B',N'Thương gia');
-- 10. Giá hạng ghế cơ bản
INSERT INTO [dbo].[HANGGHE_GIA] VALUES ('HG01', 'CB01', N'Phổ thông', 1950000), ('HG02', 'CB01', N'Thương gia', 4500000), ('HG03', 'CB02', N'Phổ thông', 1500000), ('HG04', 'CB02', N'Thương gia', 3800000), ('HG05', 'CB03', N'Phổ thông', 1800000), ('HG06', 'CB04', N'Phổ thông', 2000000), ('HG07', 'CB04', N'Thương gia', 4600000), ('HG08', 'CB06', N'Phổ thông', 1300000), ('HG09', 'CB07', N'Thương gia', 4000000), ('HG10', 'CB09', N'Phổ thông', 1750000), ('HG11', 'CB07', N'Hạng nhất', 5500000);
-- 11. Vé máy bay đã bán
INSERT INTO [dbo].[VEMAYBAY] VALUES ('VE01','GH01','HG01',1950000,'CB01','NV01'), ('VE02','GH02','HG01',2050000,'CB01','NV01'), ('VE03','GH03','HG02',4800000,'CB01','NV02'), ('VE04','GH04','HG03',1500000,'CB02','NV03'), ('VE05','GH05','HG05',1800000,'CB03','NV04'), ('VE06','GH06','HG06',2000000,'CB04','NV01'), ('VE07','GH07','HG08',1300000,'CB06','NV05'), ('VE08','GH08','HG11',5000000,'CB07','NV05'), ('VE09','GH09','HG04',3900000,'CB08','NV02'), ('VE10','GH10','HG10',1750000,'CB09','NV03');
-- 12. Giỏ hàng
INSERT INTO [dbo].[GIOHANG] VALUES ('GH01', 'KH01', '2025-11-28 10:00:00', N'Đã thanh toán'), ('GH02', 'KH02', '2025-11-28 11:30:00', N'Đã thanh toán'), ('GH03', 'KH03', '2025-11-29 15:45:00', N'Đã thanh toán'), ('GH04', 'KH04', '2025-11-29 09:00:00', N'Đã thanh toán'), ('GH05', 'KH05', '2025-11-27 18:20:00', N'Đã thanh toán'), ('GH06', 'KH06', '2025-11-27 14:00:00', N'Đã thanh toán'), ('GH07', 'KH07', '2025-11-26 12:00:00', N'Đã thanh toán'), ('GH08', 'KH08', '2025-11-29 20:00:00', N'Đang chọn'), ('GH09', 'KH09', '2025-11-25 08:00:00', N'Đã hết hạn'), ('GH10', 'KH10', '2025-11-29 21:30:00', N'Đang chọn');
-- 13. Phiếu đặt vé
INSERT INTO [dbo].[PHIEUDATVE] VALUES ('PD01', '2025-11-28', 'NV01', 'KH01', N'Đã thanh toán', 'GH01'), ('PD02', '2025-11-28', 'NV01', 'KH02', N'Đã thanh toán', 'GH02'), ('PD03', '2025-11-29', 'NV02', 'KH03', N'Đã thanh toán', 'GH01'), ('PD04', '2025-11-29', 'NV03', 'KH04', N'Hủy', 'GH04'), ('PD05', '2025-11-27', 'NV04', 'KH05', N'Đã thanh toán', 'GH03'), ('PD06', '2025-11-27', 'NV05', 'KH06', N'Đã thanh toán', 'GH02'), ('PD07', '2025-11-26', 'NV05', 'KH07', N'Đã thanh toán', 'GH05'), ('PD08', '2025-11-26', 'NV02', 'KH08', N'Đang xử lý', 'GH07'), ('PD09', '2025-11-25', 'NV03', 'KH09', N'Đã thanh toán', 'GH06'), ('PD10', '2025-11-29', 'NV04', 'KH10', N'Đang xử lý', 'GH10');
-- 14. Chi tiết vé máy bay
INSERT INTO [dbo].[CHITIETVE] VALUES ('VE01', 'PD01', '2025-11-28', 1950000), ('VE02', 'PD01', '2025-11-28', 2050000), ('VE03', 'PD03', '2025-11-29', 4800000), ('VE04', 'PD04', '2025-11-29', 1500000), ('VE05', 'PD05', '2025-11-27', 1800000), ('VE06', 'PD02', '2025-11-28', 2000000), ('VE07', 'PD06', '2025-11-27', 1300000), ('VE08', 'PD07', '2025-11-26', 5000000), ('VE09', 'PD08', '2025-11-26', 3900000), ('VE10', 'PD09', '2025-11-25', 1750000);
-- 15. Hành lý kèm theo
INSERT INTO [dbo].[HANHLY] VALUES ('HL01', 'VE01', 'CB01', N'Xách tay', 7, 50), ('HL02', 'VE06', 'CB04', N'Ký gửi', 20, 100), ('HL03', 'VE03', 'CB01', N'Ký gửi', 25, 120), ('HL04', 'VE04', 'CB02', N'Xách tay', 10, 60), ('HL05', 'VE05', 'CB03', N'Ký gửi', 15, 80), ('HL06', 'VE07', 'CB06', N'Xách tay', 5, 40), ('HL07', 'VE08', 'CB07', N'Ký gửi', 30, 150), ('HL08', 'VE09', 'CB08', N'Xách tay', 8, 55), ('HL09', 'VE10', 'CB09', N'Ký gửi', 12, 70), ('HL10', 'VE02', 'CB01', N'Xách tay', 6, 45);
-- 16. Thống kê tổng quan doanh thu ban đầu
INSERT INTO [dbo].[THONGKE_DOANHTHU] VALUES ('CB01', '2025-11-28', 4000000, 2), ('CB01', '2025-11-29', 4800000, 1), ('CB02', '2025-11-28', 1500000, 1), ('CB03', '2025-11-27', 1800000, 1), ('CB04', '2025-11-29', 2000000, 1), ('CB06', '2025-11-27', 1300000, 1), ('CB07', '2025-11-26', 5000000, 1), ('CB08', '2025-11-26', 3900000, 1), ('CB09', '2025-11-25', 1750000, 1), ('CB10', '2025-11-29', 0, 0);
-- 17. Chi tiết giỏ hàng tạm thời
INSERT INTO [dbo].[GIOHANG_CHITIET] (MAGH, MACB, SOLUONG, GIATIEN, THOIGIANGIU) VALUES ('GH01', 'CB01', 1, 4500000, DATEADD(MINUTE, 15, '2025-11-28 10:00:00')), ('GH03', 'CB04', 2, 4000000, DATEADD(MINUTE, 15, '2025-11-29 15:45:00')), ('GH05', 'CB09', 1, 1950000, DATEADD(MINUTE, 15, '2025-11-27 18:20:00')), ('GH08', 'CB01', 3, 5850000, DATEADD(MINUTE, 15, '2025-11-29 20:00:00')), ('GH10', 'CB10', 1, 2200000, DATEADD(MINUTE, 15, '2025-11-29 21:30:00')), ('GH02', 'CB02', 1, 1700000, '2025-11-28 11:45:00'), ('GH04', 'CB03', 2, 3600000, '2025-11-29 09:15:00'), ('GH06', 'CB08', 1, 3800000, '2025-11-27 14:15:00'), ('GH07', 'CB06', 1, 1300000, '2025-11-26 12:15:00'), ('GH09', 'CB01', 1, 4500000, '2025-11-25 08:15:00');
-- 18. Hành khách đăng ký trong giỏ hàng
INSERT INTO [dbo].[GIOHANG_HANHKHACH] (MAHK, SOGHE, MAGH, MACB, HANGGHE, TENHANHKHACH, NGAYSINH, GIOITINH, EMAIL, SDT, HANGLY_XACHTAY, HANHLYKYGUI) VALUES ('HK01GH01', '01A', 'GH01', 'CB01', N'Thương gia', N'Nguyễn Minh Khoa', '1990-05-12', N'Nam', 'khoa@gmail.com', '0911111111', 0, 1), ('HK01GH03', '10F', 'GH03', 'CB04', N'Phổ thông', N'John Smith', '1988-09-15', N'Nam', 'john@gmail.com', '0933333333', 0, 0), ('HK02GH03', '10E', 'GH03', 'CB04', N'Phổ thông', N'Mary Jane', '1995-02-20', N'Nữ', 'mary@example.com', '0933333334', 0, 0), ('HK01GH05', '05C', 'GH05', 'CB09', N'Phổ thông', N'Lý Thu Hà', '1998-11-25', N'Nữ', 'ha@gmail.com', '0955555555', 1, 0), ('HK01GH08', '20A', 'GH08', 'CB01', N'Phổ thông', N'David Lee', '1991-12-24', N'Nam', 'david@gmail.com', '0988888888', 0, 0), ('HK02GH08', '20B', 'GH08', 'CB01', N'Phổ thông', N'Lee Min Ho', '1987-06-22', N'Nam', 'lmh@example.com', '0988888881', 0, 0), ('HK03GH08', '20C', 'GH08', 'CB01', N'Phổ thông', N'Kim Ji Won', '1992-10-19', N'Nữ', 'kjw@example.com', '0988888882', 0, 0), ('HK01GH10', '15D', 'GH10', 'CB10', N'Phổ thông', N'Nguyễn Hùng Sơn', '1980-06-28', N'Nam', 'son@gmail.com', '0900000000', 0, 2), ('HK01GH02', '12A', 'GH02', 'CB02', N'Phổ thông', N'Lê Thanh Hoa', '1995-07-20', N'Nữ', 'hoa@gmail.com', '0922222222', 1, 0), ('HK01GH04', '18F', 'GH04', 'CB03', N'Phổ thông', N'Nguyễn Văn Nam', '1992-01-30', N'Nam', 'nam@gmail.com', '0944444444', 0, 0), ('HK01GH06', '10A', 'GH06', 'CB08', N'Phổ thông', N'Trần Đức Tài', '1985-03-10', N'Nam', 'tai@gmail.com', '0966666666', 0, 1);
GO

-- Đồng bộ đồng đều mốc thời gian hành trình thực tế cho các Proc liên quan logic thời gian
UPDATE LOTRINH SET GIOCATCANH = DATEADD(HOUR, 12, GETDATE()), GIOHACANH = DATEADD(HOUR, 14, GETDATE()) WHERE MACB = 'CB01';
GO

-- ======================================================
-- PHẦN 4: THIẾT LẬP CÁC RÀNG BUỘC (CONSTRAINTS - DEFAULT - CHECK - FK)
-- ======================================================

SET ANSI_PADDING ON
GO
ALTER TABLE [dbo].[CAUHINH_GHE] ADD CONSTRAINT [UNQ_CG] UNIQUE NONCLUSTERED ([MAMB] ASC, [HANGGHE] ASC) ON [PRIMARY]
GO
ALTER TABLE [dbo].[GIOHANG] ADD CONSTRAINT [DF_GH_NGAYTAO] DEFAULT (getdate()) FOR [NGAYTAO]
GO
ALTER TABLE [dbo].[GIOHANG] ADD CONSTRAINT [DF_GH_TRANGTHAI] DEFAULT (N'Đang chọn') FOR [TRANGTHAI]
GO
ALTER TABLE [dbo].[GIOHANG_CHITIET] ADD CONSTRAINT [DF_GHCT_SL] DEFAULT ((1)) FOR [SOLUONG]
GO
ALTER TABLE [dbo].[GIOHANG_CHITIET] ADD CONSTRAINT [DF_GHCT_TIME] DEFAULT (dateadd(minute,(15),getdate())) FOR [THOIGIANGIU]
GO
ALTER TABLE [dbo].[GIOHANG_HANHKHACH] ADD CONSTRAINT [DF_GHKH_XACHTAY] DEFAULT ((0)) FOR [HANGLY_XACHTAY]
GO
ALTER TABLE [dbo].[GIOHANG_HANHKHACH] ADD CONSTRAINT [DF_GHKH_KYGUI] DEFAULT ((0)) FOR [HANHLYKYGUI]
GO
ALTER TABLE [dbo].[KHACHHANG] ADD CONSTRAINT [DF_KH_QG] DEFAULT (N'Việt Nam') FOR [QUOCGIA]
GO
ALTER TABLE [dbo].[CAUHINH_GHE] WITH CHECK ADD CONSTRAINT [FK_CG_MB] FOREIGN KEY([MAMB]) REFERENCES [dbo].[MAYBAY] ([MAMB])
GO
ALTER TABLE [dbo].[CAUHINH_GHE] CHECK CONSTRAINT [FK_CG_MB]
GO
ALTER TABLE [dbo].[CHECKIN] WITH CHECK ADD CONSTRAINT [FK_CI_CB] FOREIGN KEY([MACB]) REFERENCES [dbo].[CHUYENBAY] ([MACB])
GO
ALTER TABLE [dbo].[CHECKIN] CHECK CONSTRAINT [FK_CI_CB]
GO
ALTER TABLE [dbo].[CHECKIN] WITH CHECK ADD CONSTRAINT [FK_CI_KH] FOREIGN KEY([MAKH]) REFERENCES [dbo].[KHACHHANG] ([MAKH])
GO
ALTER TABLE [dbo].[CHECKIN] CHECK CONSTRAINT [FK_CI_KH]
GO
ALTER TABLE [dbo].[CHECKIN] WITH CHECK ADD CONSTRAINT [FK_CI_VE] FOREIGN KEY([MAVE]) REFERENCES [dbo].[VEMAYBAY] ([MAVE])
GO
ALTER TABLE [dbo].[CHECKIN] CHECK CONSTRAINT [FK_CI_VE]
GO
ALTER TABLE [dbo].[CHITIETVE] WITH CHECK ADD CONSTRAINT [FK_CTV_PDV] FOREIGN KEY([MAPHIEU]) REFERENCES [dbo].[PHIEUDATVE] ([MAPHIEU])
GO
ALTER TABLE [dbo].[CHITIETVE] CHECK CONSTRAINT [FK_CTV_PDV]
GO
ALTER TABLE [dbo].[CHITIETVE] WITH CHECK ADD CONSTRAINT [FK_CTV_VE] FOREIGN KEY([MAVE]) REFERENCES [dbo].[VEMAYBAY] ([MAVE])
GO
ALTER TABLE [dbo].[CHITIETVE] CHECK CONSTRAINT [FK_CTV_VE]
GO
ALTER TABLE [dbo].[CHUYENBAY] WITH CHECK ADD CONSTRAINT [FK_CB_MB] FOREIGN KEY([MAMB]) REFERENCES [dbo].[MAYBAY] ([MAMB])
GO
ALTER TABLE [dbo].[CHUYENBAY] CHECK CONSTRAINT [FK_CB_MB]
GO
ALTER TABLE [dbo].[GHE] WITH CHECK ADD CONSTRAINT [FK_GHE_MB] FOREIGN KEY([MAMB]) REFERENCES [dbo].[MAYBAY] ([MAMB])
GO
ALTER TABLE [dbo].[GHE] CHECK CONSTRAINT [FK_GHE_MB]
GO
ALTER TABLE [dbo].[GIOHANG] WITH CHECK ADD CONSTRAINT [FK_GH_KH] FOREIGN KEY([MAKH]) REFERENCES [dbo].[KHACHHANG] ([MAKH])
GO
ALTER TABLE [dbo].[GIOHANG] CHECK CONSTRAINT [FK_GH_KH]
GO
ALTER TABLE [dbo].[GIOHANG_CHITIET] WITH CHECK ADD CONSTRAINT [FK_GHCT_CB] FOREIGN KEY([MACB]) REFERENCES [dbo].[CHUYENBAY] ([MACB])
GO
ALTER TABLE [dbo].[GIOHANG_CHITIET] CHECK CONSTRAINT [FK_GHCT_CB]
GO
ALTER TABLE [dbo].[GIOHANG_CHITIET] WITH CHECK ADD CONSTRAINT [FK_GHCT_GH] FOREIGN KEY([MAGH]) REFERENCES [dbo].[GIOHANG] ([MAGH])
GO
ALTER TABLE [dbo].[GIOHANG_CHITIET] CHECK CONSTRAINT [FK_GHCT_GH]
GO
ALTER TABLE [dbo].[GIOHANG_HANHKHACH] WITH CHECK ADD CONSTRAINT [FK_GHKH_CB] FOREIGN KEY([MACB]) REFERENCES [dbo].[CHUYENBAY] ([MACB])
GO
ALTER TABLE [dbo].[GIOHANG_HANHKHACH] CHECK CONSTRAINT [FK_GHKH_CB]
GO
ALTER TABLE [dbo].[GIOHANG_HANHKHACH] WITH CHECK ADD CONSTRAINT [FK_GHKH_GH] FOREIGN KEY([MAGH]) REFERENCES [dbo].[GIOHANG] ([MAGH])
GO
ALTER TABLE [dbo].[GIOHANG_HANHKHACH] CHECK CONSTRAINT [FK_GHKH_GH]
GO
ALTER TABLE [dbo].[HANGGHE_GIA] WITH CHECK ADD CONSTRAINT [FK_HGG_CB] FOREIGN KEY([MACB]) REFERENCES [dbo].[CHUYENBAY] ([MACB])
GO
ALTER TABLE [dbo].[HANGGHE_GIA] CHECK CONSTRAINT [FK_HGG_CB]
GO
ALTER TABLE [dbo].[HANHLY] WITH CHECK ADD CONSTRAINT [FK_HL_CB] FOREIGN KEY([MACB]) REFERENCES [dbo].[CHUYENBAY] ([MACB])
GO
ALTER TABLE [dbo].[HANHLY] CHECK CONSTRAINT [FK_HL_CB]
GO
ALTER TABLE [dbo].[HANHLY] WITH CHECK ADD CONSTRAINT [FK_HL_KH] FOREIGN KEY([MAVE]) REFERENCES [dbo].[VEMAYBAY] ([MAVE])
GO
ALTER TABLE [dbo].[HANHLY] CHECK CONSTRAINT [FK_HL_KH]
GO
ALTER TABLE [dbo].[LOTRINH] WITH CHECK ADD CONSTRAINT [FK_LT_CB] FOREIGN KEY([MACB]) REFERENCES [dbo].[CHUYENBAY] ([MACB])
GO
ALTER TABLE [dbo].[LOTRINH] CHECK CONSTRAINT [FK_LT_CB]
GO
ALTER TABLE [dbo].[LOTRINH] WITH CHECK ADD CONSTRAINT [FK_LT_SBDEN] FOREIGN KEY([SBDEN]) REFERENCES [dbo].[SANBAY] ([MASB])
GO
ALTER TABLE [dbo].[LOTRINH] CHECK CONSTRAINT [FK_LT_SBDEN]
GO
ALTER TABLE [dbo].[LOTRINH] WITH CHECK ADD CONSTRAINT [FK_LT_SBDI] FOREIGN KEY([SBDI]) REFERENCES [dbo].[SANBAY] ([MASB])
GO
ALTER TABLE [dbo].[LOTRINH] CHECK CONSTRAINT [FK_LT_SBDI]
GO
ALTER TABLE [dbo].[NHANVIEN] WITH CHECK ADD CONSTRAINT [FK_NV_CV] FOREIGN KEY([MACV]) REFERENCES [dbo].[CHUCVU] ([MACV])
GO
ALTER TABLE [dbo].[NHANVIEN] CHECK CONSTRAINT [FK_NV_CV]
GO
ALTER TABLE [dbo].[PHIEUDATVE] WITH CHECK ADD CONSTRAINT [FK_PDV_GH] FOREIGN KEY([MAGH]) REFERENCES [dbo].[GIOHANG] ([MAGH])
GO
ALTER TABLE [dbo].[PHIEUDATVE] CHECK CONSTRAINT [FK_PDV_GH]
GO
ALTER TABLE [dbo].[PHIEUDATVE] WITH CHECK ADD CONSTRAINT [FK_PDV_KH] FOREIGN KEY([MAKH]) REFERENCES [dbo].[KHACHHANG] ([MAKH])
GO
ALTER TABLE [dbo].[PHIEUDATVE] CHECK CONSTRAINT [FK_PDV_KH]
GO
ALTER TABLE [dbo].[PHIEUDATVE] WITH CHECK ADD CONSTRAINT [FK_PDV_NV] FOREIGN KEY([MANV]) REFERENCES [dbo].[NHANVIEN] ([MANV])
GO
ALTER TABLE [dbo].[PHIEUDATVE] CHECK CONSTRAINT [FK_PDV_NV]
GO
ALTER TABLE [dbo].[THONGKE_DOANHTHU] WITH CHECK ADD CONSTRAINT [FK_TK_CB] FOREIGN KEY([MACB]) REFERENCES [dbo].[CHUYENBAY] ([MACB])
GO
ALTER TABLE [dbo].[THONGKE_DOANHTHU] CHECK CONSTRAINT [FK_TK_CB]
GO
ALTER TABLE [dbo].[VEMAYBAY] WITH CHECK ADD CONSTRAINT [FK_VMB_CB] FOREIGN KEY([MACB]) REFERENCES [dbo].[CHUYENBAY] ([MACB])
GO
ALTER TABLE [dbo].[VEMAYBAY] CHECK CONSTRAINT [FK_VMB_CB]
GO
ALTER TABLE [dbo].[VEMAYBAY] WITH CHECK ADD CONSTRAINT [FK_VMB_GHE] FOREIGN KEY([MAGHE]) REFERENCES [dbo].[GHE] ([MAGHE])
GO
ALTER TABLE [dbo].[VEMAYBAY] CHECK CONSTRAINT [FK_VMB_GHE]
GO
ALTER TABLE [dbo].[VEMAYBAY] WITH CHECK ADD CONSTRAINT [FK_VMB_HGG] FOREIGN KEY([MAHG]) REFERENCES [dbo].[HANGGHE_GIA] ([MAHG])
GO
ALTER TABLE [dbo].[VEMAYBAY] CHECK CONSTRAINT [FK_VMB_HGG]
GO
ALTER TABLE [dbo].[VEMAYBAY] WITH CHECK ADD CONSTRAINT [FK_VMB_NV] FOREIGN KEY([MANV]) REFERENCES [dbo].[NHANVIEN] ([MANV])
GO
ALTER TABLE [dbo].[VEMAYBAY] CHECK CONSTRAINT [FK_VMB_NV]
GO
ALTER TABLE [dbo].[CHUYENBAY] WITH CHECK ADD CONSTRAINT [CHK_CB_TRANGTHAI] CHECK (([TRANGTHAI]=N'Đúng giờ' OR [TRANGTHAI]=N'Hủy' OR [TRANGTHAI]=N'Đã hạ cánh' OR [TRANGTHAI]=N'Chờ bay' OR [TRANGTHAI]=N'Đang bay'))
GO
ALTER TABLE [dbo].[CHUYENBAY] CHECK CONSTRAINT [CHK_CB_TRANGTHAI]
GO
ALTER TABLE [dbo].[KHACHHANG] WITH CHECK ADD CONSTRAINT [CHK_KH_GTINH] CHECK (([GTINH]=N'Khác' OR [GTINH]=N'Nữ' OR [GTINH]=N'Nam'))
GO
ALTER TABLE [dbo].[KHACHHANG] CHECK CONSTRAINT [CHK_KH_GTINH]
GO

-- ======================================================
-- PHẦN 5: ĐỊNH NGHĨA CÁC THỦ TỤC & KÍCH HOẠT (STORED PROCEDURES - TRIGGERS)
-- ======================================================

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- 1. Thủ tục: Backup Cơ sở dữ liệu theo phân loại
CREATE PROCEDURE [dbo].[sp_BackupDatabase]
    @DuongDanFile NVARCHAR(255),
    @LoaiBackup VARCHAR(10)
AS
BEGIN
    DECLARE @DbName NVARCHAR(50) = DB_NAME();
    IF @LoaiBackup = 'full'
    BEGIN
        BACKUP DATABASE @DbName TO DISK = @DuongDanFile WITH INIT, NAME = 'Full Backup';
    END
    ELSE IF @LoaiBackup = 'diff'
    BEGIN
        BACKUP DATABASE @DbName TO DISK = @DuongDanFile WITH DIFFERENTIAL, NAME = 'Diff Backup';
    END
    ELSE IF @LoaiBackup = 'log'
    BEGIN
        BACKUP LOG @DbName TO DISK = @DuongDanFile WITH NAME = 'Transaction Log Backup';
    END
END;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- 2. Thủ tục: Đồng bộ tạo phiếu đặt vé tự động từ giỏ hàng đã duyệt qua Cursor
CREATE PROCEDURE [dbo].[sp_CursorTaoPhieuDatVe]
AS
BEGIN
    DECLARE @MAGH CHAR(10), @MAKH CHAR(10), @NewMaPhieu CHAR(10);
    DECLARE cur CURSOR FOR
        SELECT MAGH, MAKH FROM GIOHANG
        WHERE TRANGTHAI = N'Đã thanh toán' AND MAGH NOT IN (SELECT MAGH FROM PHIEUDATVE);
    OPEN cur;
    FETCH NEXT FROM cur INTO @MAGH, @MAKH;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @NewMaPhieu = 'PD' + RIGHT('0000' + CAST(ABS(CHECKSUM(NEWID())) % 9999 AS VARCHAR(10)), 4);
        INSERT INTO PHIEUDATVE (MAPHIEU, NGLAP, MANV, MAKH, TRANGTHAI, MAGH)
        VALUES (@NewMaPhieu, GETDATE(), 'NV01', @MAKH, N'Đã thanh toán', @MAGH);
        FETCH NEXT FROM cur INTO @MAGH, @MAKH;
    END
    CLOSE cur;
    DEALLOCATE cur;
END;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- 3. Thủ tục đặt vé chính xác cho Khách hàng từ thông tin Giỏ hàng hành khách
CREATE PROCEDURE [dbo].[sp_DatVe]
    @MaKH CHAR(10),
    @MaNV CHAR(10),
    @MAGH CHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    BEGIN TRY
        DECLARE @MaPhieu CHAR(10) = 'PDV' + RIGHT(CAST(ABS(CHECKSUM(NEWID())) AS VARCHAR(10)), 6);
        INSERT INTO PHIEUDATVE(MAPHIEU, NGLAP, MANV, MAKH, TRANGTHAI, MAGH)
        VALUES (@MaPhieu, GETDATE(), @MaNV, @MaKH, N'Đã đặt', @MAGH);

        DECLARE @MAHK CHAR(20), @MAGHE CHAR(10), @MACB CHAR(10), @GIATIEN MONEY, @MAHG CHAR(10), @MaVe CHAR(10), @TenHang NVARCHAR(20);

        DECLARE cur CURSOR LOCAL FOR
            SELECT ghh.MAHK, g.MAGHE, ghh.MACB, ghh.HANGGHE
            FROM GIOHANG_HANHKHACH ghh
            JOIN GHE g ON g.TENGHE = ghh.SOGHE
            WHERE ghh.MAGH = @MAGH;

        OPEN cur;
        FETCH NEXT FROM cur INTO @MAHK, @MAGHE, @MACB, @TenHang;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SELECT @MAHG = MAHG, @GIATIEN = GIA_COSO
            FROM HANGGHE_GIA
            WHERE MACB = @MACB AND HANGGHE = @TenHang;

            IF @MAHG IS NULL
            BEGIN
                RAISERROR(N'Hạng ghế không tồn tại trong HANGGHE_GIA', 16, 1);
                RETURN;
            END

            SET @MaVe = 'VE' + RIGHT(CAST(ABS(CHECKSUM(NEWID())) AS VARCHAR(10)), 6);
            INSERT INTO VEMAYBAY(MAVE, MAGHE, MAHG, GIAVE, MACB, MANV)
            VALUES (@MaVe, @MAGHE, @MAHG, @GIATIEN, @MACB, @MaNV);

            INSERT INTO CHITIETVE(MAVE, MAPHIEU, NGAYDAT, GIATIEN)
            VALUES (@MaVe, @MaPhieu, GETDATE(), @GIATIEN);

            FETCH NEXT FROM cur INTO @MAHK, @MAGHE, @MACB, @TenHang;
        END;
        CLOSE cur;
        DEALLOCATE cur;
    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local', 'cur') >= 0
        BEGIN
            CLOSE cur;
            DEALLOCATE cur;
        END
        PRINT(ERROR_MESSAGE());
        RAISERROR(N'Lỗi trong tiến trình xử lý sp_DatVe', 16, 1);
        RETURN;
    END CATCH
END;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- 4. Thủ tục: Bàn giao công việc và xóa nhân viên an toàn qua Transaction
CREATE PROCEDURE [dbo].[sp_DeleteEmployee_SafeTransaction]
    @MaNVCuaBan CHAR(10),
    @MaNVNhanBanGiao CHAR(10)
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    BEGIN TRANSACTION;
    BEGIN TRY
        IF @MaNVCuaBan = @MaNVNhanBanGiao
        BEGIN
            RAISERROR(N'Không thể tự xóa chính tài khoản bản thân!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        UPDATE VEMAYBAY SET MANV = @MaNVNhanBanGiao WHERE MANV = @MaNVCuaBan;
        UPDATE PHIEUDATVE SET MANV = @MaNVNhanBanGiao WHERE MANV = @MaNVCuaBan;
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

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- 5. Thủ tục: Định kỳ tự dọn dẹp các giỏ hàng hết hạn giữ vé
CREATE PROCEDURE [dbo].[sp_DonVeHetHan]
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    BEGIN TRANSACTION;
    DELETE FROM GIOHANG_CHITIET WHERE THOIGIANGIU < GETDATE();
    UPDATE GIOHANG SET TRANGTHAI = N'Đã hết hạn'
    WHERE TRANGTHAI = N'Đang chọn' AND NGAYTAO < DATEADD(MINUTE, -15, GETDATE());
    COMMIT TRANSACTION;
END;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- 6. Thủ tục: Truy cứu nhanh hiện trạng chuyến bay bằng thời gian thực tế
CREATE PROCEDURE [dbo].[sp_KiemTraTrangThaiChuyenBay]
    @MACB CHAR(10)
AS
BEGIN
    DECLARE @GioCatCanh DATETIME, @GioHaCanh DATETIME, @Now DATETIME = GETDATE();
    SELECT @GioCatCanh = GIOCATCANH, @GioHaCanh = GIOHACANH FROM LOTRINH WHERE MACB = @MACB;
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

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- 7. Thủ tục: Xác nhận đổi trạng thái giỏ hàng đã thanh toán thành công
CREATE PROCEDURE [dbo].[SP_ThanhToanGioHang]
    @MAGH CHAR(10)
AS
BEGIN
    UPDATE GIOHANG SET TRANGTHAI = N'Đã Thanh Toán' WHERE MAGH = @MAGH;
END
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- 8. Thủ tục: Tổng hợp báo cáo doanh thu theo tháng chỉ định
CREATE PROCEDURE [dbo].[sp_TinhTongDoanhThu_Thang]
    @Thang INT,
    @Nam INT,
    @TongDoanhThu MONEY OUTPUT
AS
BEGIN
    SELECT @TongDoanhThu = ISNULL(SUM(CT.GIATIEN), 0)
    FROM CHITIETVE CT
    WHERE MONTH(CT.NGAYDAT) = @Thang AND YEAR(CT.NGAYDAT) = @Nam;
END;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- 9. Thủ tục: Quét cập nhật tự động toàn bộ trạng thái chuyến bay thực tế bằng Cursors
CREATE PROCEDURE [dbo].[sp_UpdateFlightStatus_Cursor]
AS
BEGIN
    DECLARE @MaCB CHAR(10), @GioCatCanh DATETIME, @GioHaCanh DATETIME, @TrangThaiMoi NVARCHAR(50), @Count INT = 0;
    DECLARE cur_FlightStatus CURSOR FOR
    SELECT C.MACB, L.GIOCATCANH, L.GIOHACANH FROM CHUYENBAY C
    JOIN LOTRINH L ON C.MACB = L.MACB WHERE C.TRANGTHAI NOT IN (N'Hủy', N'Đã hạ cánh');
    OPEN cur_FlightStatus;
    FETCH NEXT FROM cur_FlightStatus INTO @MaCB, @GioCatCanh, @GioHaCanh;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @TrangThaiMoi = NULL;
        IF GETDATE() > @GioHaCanh SET @TrangThaiMoi = N'Đã hạ cánh';
        ELSE IF GETDATE() >= @GioCatCanh AND GETDATE() <= @GioHaCanh SET @TrangThaiMoi = N'Đang bay';
        IF @TrangThaiMoi IS NOT NULL
        BEGIN
            UPDATE CHUYENBAY SET TRANGTHAI = @TrangThaiMoi WHERE MACB = @MaCB;        
            SET @Count = @Count + 1;
        END
        FETCH NEXT FROM cur_FlightStatus INTO @MaCB, @GioCatCanh, @GioHaCanh;
    END
    CLOSE cur_FlightStatus;
    DEALLOCATE cur_FlightStatus;
    SELECT @Count AS RowsAffected;
END;
GO

-- ======================================================
-- KÍCH HOẠT (TRIGGERS RÀNG BUỘC NGHIỆP VỤ)
-- ======================================================

CREATE TRIGGER trg_SafeGuard_Director
ON NHANVIEN
FOR DELETE, UPDATE
AS
BEGIN
    IF EXISTS (SELECT * FROM deleted WHERE MACV = 'CV09')
    BEGIN
        DECLARE @RemainingDirector INT;
        SELECT @RemainingDirector = COUNT(*) FROM NHANVIEN WHERE MACV = 'CV09';
        IF @RemainingDirector < 1
        BEGIN
            PRINT N'LỖI: Không thể thực hiện hành động xóa hoặc giáng chức Giám đốc duy nhất còn lại!';
            ROLLBACK TRANSACTION;
        END
    END
END;
GO

CREATE TRIGGER trg_CheckTuoiHanhKhach
ON GIOHANG_HANHKHACH
FOR INSERT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted WHERE DATEDIFF(YEAR, NGAYSINH, GETDATE()) < 2)
    BEGIN
        RAISERROR(N'Hành khách bắt buộc phải đạt độ tuổi từ đủ 2 tuổi trở lên!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

CREATE TRIGGER trg_CapNhatDoanhThu
ON CHITIETVE
FOR INSERT
AS
BEGIN
    DECLARE @MaCB CHAR(10), @Ngay DATE, @TongTien MONEY, @SoLuong INT;
    SELECT @MaCB = V.MACB, @Ngay = CAST(I.NGAYDAT AS DATE), @TongTien = SUM(I.GIATIEN), @SoLuong = COUNT(I.MAVE)
    FROM INSERTED I JOIN VEMAYBAY V ON I.MAVE = V.MAVE
    GROUP BY V.MACB, CAST(I.NGAYDAT AS DATE);

    IF EXISTS (SELECT 1 FROM THONGKE_DOANHTHU WHERE MACB = @MaCB AND NGAY = @Ngay)
    BEGIN
        UPDATE THONGKE_DOANHTHU SET TONGDOANHTHU = TONGDOANHTHU + @TongTien, SOLUONGVE = SOLUONGVE + @SoLuong
        WHERE MACB = @MaCB AND NGAY = @Ngay;
    END
    ELSE
    BEGIN
        INSERT INTO THONGKE_DOANHTHU (MACB, NGAY, TONGDOANHTHU, SOLUONGVE) VALUES (@MaCB, @Ngay, @TongTien, @SoLuong);
    END
END;
GO