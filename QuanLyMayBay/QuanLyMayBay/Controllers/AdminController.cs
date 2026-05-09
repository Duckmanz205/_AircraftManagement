using BCrypt.Net;
using ClosedXML.Excel;
using OtpNet;
using QuanLyMayBay.Models;
using QuanLyMayBay.Models.Admin;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.Entity;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace QuanLyMayBay.Controllers
{
    public class AdminController : Controller
    {
        // GET: Admin
        QUANLYMAYBAYEntities db = new QUANLYMAYBAYEntities();

        // POST: Admin/DangNhapThanhCong
        [HttpPost]
        public ActionResult DangNhapThanhCong(FormCollection form)
        {
            // 1. Lấy thông tin từ form
            string username = form["adminId"]; // Mã nhân viên (MANV)
            string password = form["adminPassword"]; // Số điện thoại (SDT)

            // 2. Tìm Nhân viên theo MANV (username)
            // .Trim() để loại bỏ khoảng trắng dư thừa trong chuỗi
            NHANVIEN nhanVien = db.NHANVIENs.FirstOrDefault(nv => nv.MANV.Trim() == username.Trim());

            // 3. Kiểm tra thông tin đăng nhập
            if (nhanVien == null)
            {
                // Không tìm thấy nhân viên
                Session["AdminError"] = "Mã nhân viên không tồn tại.";
                return RedirectToAction("DangNhap", "User");
            }

            // Kiểm tra mật khẩu (SDT)
            // .Trim() cho cả hai để đảm bảo khớp chính xác
            if (nhanVien.MATKHAU.Trim() != password.Trim())
            {
                // Mật khẩu (SDT) không đúng
                Session["AdminError"] = "Mật khẩu (SĐT) không chính xác.";
                return RedirectToAction("DangNhap", "User");
            }

            // 4. Đăng nhập thành công
            // Lưu thông tin nhân viên vào Session
            Session["AdminUser"] = nhanVien;
            Session["AdminError"] = null; // Xóa lỗi

            return RedirectToAction("TrangChu");
        }



        public ActionResult DangXuat()
        {
            Session["AdminLoggedIn"] = null;
            Session["AdminName"] = null;
            Session["AdminMANV"] = null;

            Session.Clear();
            Session.Abandon();

            Response.Cache.SetCacheability(HttpCacheability.NoCache);
            Response.Cache.SetExpires(DateTime.UtcNow.AddHours(-1));
            Response.Cache.SetNoStore();

            return RedirectToAction("DangNhap", "User");
        }
        public ActionResult TrangChu()
        {
            if (Session["AdminUser"] == null) return RedirectToAction("DangNhap", "User");
            DateTime today = DateTime.Today; // Lấy ngày hôm nay (00:00:00)



            DateTime yesterday = today.AddDays(-1);

            // --- 1. LẤY DANH SÁCH PHIẾU ĐẶT VÉ ---
            var recentBookings = (from ctv in db.CHITIETVEs
                                  join pdv in db.PHIEUDATVEs on ctv.MAPHIEU equals pdv.MAPHIEU
                                  join kh in db.KHACHHANGs on pdv.MAKH equals kh.MAKH
                                  orderby ctv.NGAYDAT descending // Sắp xếp mới nhất
                                  select new PhieuDatVeDisplay
                                  {
                                      MAPHIEU = ctv.MAPHIEU,
                                      MAVE = ctv.MAVE,
                                      TENKH = kh.TENKH,
                                      NGAYDAT = ctv.NGAYDAT,
                                      GIATIEN = ctv.GIATIEN ?? 0,
                                      TRANGTHAI = pdv.TRANGTHAI
                                  }).Take(10).ToList(); // Chỉ lấy 10 cái mới nhất cho bảng

            // --- 2. TÍNH TOÁN KPI ---

            // A. Doanh thu
            var dtHomNay = (decimal)(db.CHITIETVEs.Where(x => x.NGAYDAT == today).Sum(x => (long?)x.GIATIEN) ?? 0);
            var dtHomQua = (decimal)(db.CHITIETVEs.Where(x => x.NGAYDAT == yesterday).Sum(x => (long?)x.GIATIEN) ?? 0);
            double phanTramDT = dtHomQua > 0 ? (double)((dtHomNay - dtHomQua) / dtHomQua) * 100 : 100;

            // B. Vé bán
            var veHomNay = db.CHITIETVEs.Count(x => x.NGAYDAT == today);
            var veHomQua = db.CHITIETVEs.Count(x => x.NGAYDAT == yesterday);
            double phanTramVe = veHomQua > 0 ? (double)((veHomNay - veHomQua) / (double)veHomQua) * 100 : 100;

            // C. Chuyến bay (Trạng thái lấy từ bảng CHUYENBAY)
            var dangBay = db.CHUYENBAYs.Count(x => x.TRANGTHAI == "Đang bay");
            var dungGio = db.CHUYENBAYs.Count(x => x.TRANGTHAI == "Đúng giờ");

            // D. Tỷ lệ trễ
            var totalFlight = db.CHUYENBAYs.Count();
            var delayedFlight = db.CHUYENBAYs.Count(x => x.TRANGTHAI == "Chậm trễ" || x.TRANGTHAI == "Delay");
            double tyLeTre = totalFlight > 0 ? (double)delayedFlight / totalFlight * 100 : 0;

            // --- 3. DỮ LIỆU BIỂU ĐỒ ---

            // A. Biểu đồ doanh thu 7 ngày gần nhất
            var sevenDaysAgo = today.AddDays(-6);

            // BƯỚC 1: Chỉ lấy dữ liệu thô về trước (Dùng .ToList() để ngắt kết nối DB ngay lập tức)
            // Lưu ý: Select những trường cần thiết để nhẹ gánh
            var rawData = db.CHITIETVEs
                .Where(x => x.NGAYDAT >= sevenDaysAgo)
                .Select(x => new { x.NGAYDAT, x.GIATIEN })
                .ToList();

            // BƯỚC 2: Xử lý tính toán GroupBy trên RAM (C#) - Nhanh hơn và không bao giờ Timeout
            var revenueData = rawData
                .GroupBy(x => x.NGAYDAT)
                .Select(g => new
                {
                    Ngay = g.Key,
                    // Lúc này dữ liệu đã ở trên RAM, tính toán thoải mái không lo lỗi SQL
                    TongTien = g.Sum(x => (decimal?)x.GIATIEN) ?? 0
                })
                .ToList();

            // Chuẩn hóa dữ liệu biểu đồ (điền 0 cho những ngày không có doanh thu)
            List<string> labelsChart1 = new List<string>();
            List<decimal> valuesChart1 = new List<decimal>();

            for (int i = 6; i >= 0; i--)
            {
                var dateCheck = today.AddDays(-i);
                labelsChart1.Add(dateCheck.ToString("dd/MM"));
                var data = revenueData.FirstOrDefault(x => x.Ngay == dateCheck);
                valuesChart1.Add(data != null ? data.TongTien : 0);
            }

            // B. Top 5 chuyến bay bán chạy nhất (Dựa trên số lượng vé trong bảng VEMAYBAY)
            // Join CHUYENBAY -> LOTRINH -> SANBAY để lấy tên hành trình cho đẹp (VD: Ha Noi - HCM)
            var topFlights = (from v in db.VEMAYBAYs
                              join cb in db.CHUYENBAYs on v.MACB equals cb.MACB
                              join lt in db.LOTRINHs on cb.MACB equals lt.MACB
                              join sbDi in db.SANBAYs on lt.SBDI equals sbDi.MASB
                              join sbDen in db.SANBAYs on lt.SBDEN equals sbDen.MASB
                              group v by new { cb.MACB, sbDi.THANHPHO, DenTP = sbDen.THANHPHO } into g
                              orderby g.Count() descending
                              select new
                              {
                                  TenChuyen = g.Key.THANHPHO + " - " + g.Key.DenTP,
                                  SoLuong = g.Count()
                              }).Take(5).ToList();

            // --- 4. TỔNG HỢP VÀO VIEWMODEL ---
            var model = new DashboardViewModel
            {
                DanhSachPhieuDat = recentBookings,

                // KPI
                DoanhThuHomNay = dtHomNay,
                PhanTramDoanhThu = Math.Round(phanTramDT, 1),
                VeBanHomNay = veHomNay,
                PhanTramVeBan = Math.Round(phanTramVe, 1),
                ChuyenBayDangBay = dangBay,
                ChuyenBayDungGio = dungGio,
                TyLeTreChuyen = Math.Round(tyLeTre, 1),
                PhanTramTreChuyen = 1.2, // Fake số liệu so sánh vì DB ko có lịch sử trạng thái chuyến bay

                // Charts
                ChartLabels = labelsChart1,
                ChartRevenueData = valuesChart1,
                TopFlightLabels = topFlights.Select(x => x.TenChuyen).ToList(),
                TopFlightData = topFlights.Select(x => x.SoLuong).ToList()
            };

            return View(model);
        }

        public ActionResult ThongKe(DateTime? startDate, DateTime? endDate, string searchQuery, int page = 1)
        {
            if (Session["AdminUser"] == null) return RedirectToAction("DangNhap", "User");

            // 2. Thiết lập ngày tháng mặc định
            DateTime today = DateTime.Today;
            if (!startDate.HasValue) startDate = new DateTime(today.Year, 1, 1);
            if (!endDate.HasValue) endDate = today;
            DateTime filterEndDate = endDate.Value.AddDays(1);

            // Lưu lại giá trị để hiển thị lên View
            ViewBag.StartDate = startDate.Value;
            ViewBag.EndDate = endDate.Value;
            ViewBag.SearchQuery = searchQuery;

            // 3. Truy vấn & Gom nhóm dữ liệu (Lấy TOÀN BỘ kết quả lọc trước)
            var query = (from ctv in db.CHITIETVEs
                         join vmb in db.VEMAYBAYs on ctv.MAVE equals vmb.MAVE
                         join cb in db.CHUYENBAYs on vmb.MACB equals cb.MACB
                         join lt in db.LOTRINHs on cb.MACB equals lt.MACB
                         where ctv.NGAYDAT >= startDate.Value && ctv.NGAYDAT < filterEndDate
                         group new { ctv, lt } by new { cb.MACB, lt.GIOCATCANH.Year, lt.GIOCATCANH.Month, lt.GIOCATCANH.Day } into g
                         select new ChiTietDoanhThuModel
                         {
                             MaChuyenBay = g.Key.MACB,
                             NgayBay = DbFunctions.CreateDateTime(g.Key.Year, g.Key.Month, g.Key.Day, 0, 0, 0).Value,
                             SoVe = g.Count(),
                             DoanhThu = g.Sum(x => (decimal)x.ctv.GIATIEN.Value),
                             GiaTrungBinh = (decimal)g.Average(x => (decimal)x.ctv.GIATIEN.Value)
                         });

            // Áp dụng tìm kiếm
            if (!string.IsNullOrEmpty(searchQuery))
            {
                string searchUpper = searchQuery.Trim().ToUpper();
                query = query.Where(x => x.MaChuyenBay.ToUpper().Contains(searchUpper));
            }

            // Lấy danh sách đầy đủ về bộ nhớ để tính tổng
            var fullList = query.OrderByDescending(x => x.NgayBay).ToList();

            // 4. Tính toán các chỉ số tổng quan (KPI) dựa trên FULL danh sách
            var model = new AdminThongKeViewModel
            {
                TongDoanhThu = fullList.Sum(x => x.DoanhThu),
                TongSoVeBan = fullList.Sum(x => x.SoVe),
                TongSoChuyenBay = fullList.Select(x => x.MaChuyenBay).Distinct().Count(),
                GiaVeTrungBinh = fullList.Any() ? (decimal)fullList.Average(x => x.GiaTrungBinh) : 0M
            };

            // 5. Xử lý Phân trang cho Bảng chi tiết
            int pageSize = 10;
            int totalRows = fullList.Count; // Tổng số dòng (số nhóm chuyến bay)
            int totalPages = (int)Math.Ceiling((double)totalRows / pageSize);

            // Đảm bảo page hợp lệ
            page = Math.Max(1, Math.Min(page, totalPages > 0 ? totalPages : 1));

            // Cắt dữ liệu cho trang hiện tại
            model.ChiTietDoanhThu = fullList.Skip((page - 1) * pageSize).Take(pageSize).ToList();

            // Truyền thông tin phân trang qua ViewBag
            ViewBag.CurrentPage = page;
            ViewBag.TotalPages = totalPages;
            ViewBag.TotalRows = totalRows; // Số dòng bảng (để hiển thị chính xác)

            return View(model);
        }

        // 
        private List<ChiTietDoanhThuModel> GetFilteredData(DateTime? startDate, DateTime? endDate, string searchQuery)
        {
            // Tái sử dụng logic xác định ngày tháng và tạo query từ hàm ThongKe
            DateTime today = DateTime.Today;

            if (!startDate.HasValue) { startDate = new DateTime(today.Year, today.Month, 1); }
            if (!endDate.HasValue) { endDate = today; }

            DateTime filterEndDate = endDate.Value.AddDays(1);

            var query = (from ctv in db.CHITIETVEs
                         join vmb in db.VEMAYBAYs on ctv.MAVE equals vmb.MAVE
                         join cb in db.CHUYENBAYs on vmb.MACB equals cb.MACB
                         join lt in db.LOTRINHs on cb.MACB equals lt.MACB
                         where ctv.NGAYDAT >= startDate.Value && ctv.NGAYDAT < filterEndDate
                         group new { ctv, lt } by new { cb.MACB, lt.GIOCATCANH.Year, lt.GIOCATCANH.Month, lt.GIOCATCANH.Day } into g
                         select new ChiTietDoanhThuModel
                         {
                             MaChuyenBay = g.Key.MACB,
                             NgayBay = DbFunctions.CreateDateTime(g.Key.Year, g.Key.Month, g.Key.Day, 0, 0, 0).Value,
                             SoVe = g.Count(),
                             DoanhThu = g.Sum(x => (decimal)x.ctv.GIATIEN.Value),
                             GiaTrungBinh = (decimal)g.Average(x => (decimal)x.ctv.GIATIEN.Value)
                         });

            // Áp dụng tìm kiếm
            if (!string.IsNullOrEmpty(searchQuery))
            {
                string searchUpper = searchQuery.Trim().ToUpper();
                query = query.Where(x => x.MaChuyenBay.ToUpper().Contains(searchUpper));
            }

            return query.OrderByDescending(x => x.NgayBay).ToList();
        }

        // XUẤT EXCEL
        public ActionResult ExportExcel(DateTime? startDate, DateTime? endDate, string searchQuery)
        {
            var data = GetFilteredData(startDate, endDate, searchQuery);

            // 1. Tạo workbook mới
            using (var workbook = new XLWorkbook())
            {
                var worksheet = workbook.Worksheets.Add("BaoCaoDoanhThu");

                // 2. Thiết lập Header
                worksheet.Cell(1, 1).Value = "Mã Chuyến Bay";
                worksheet.Cell(1, 2).Value = "Ngày Bay";
                worksheet.Cell(1, 3).Value = "Số Vé";
                worksheet.Cell(1, 4).Value = "Doanh Thu";
                worksheet.Cell(1, 5).Value = "Giá Trung Bình";

                // 3. Đổ dữ liệu
                int row = 2;
                foreach (var item in data)
                {
                    worksheet.Cell(row, 1).Value = item.MaChuyenBay;
                    worksheet.Cell(row, 2).Value = item.NgayBay.ToString("dd/MM/yyyy");
                    worksheet.Cell(row, 3).Value = item.SoVe;
                    worksheet.Cell(row, 4).Value = item.DoanhThu;
                    worksheet.Cell(row, 5).Value = item.GiaTrungBinh;
                    row++;
                }

                // 4. Trả về file
                using (var stream = new MemoryStream())
                {
                    workbook.SaveAs(stream);
                    var content = stream.ToArray();

                    return File(
                        content,
                        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                        $"BaoCaoDoanhThu_{DateTime.Now.ToString("yyyyMMdd")}.xlsx"
                    );
                }
            }
        }

        // XUẤT PDF
        public ActionResult ExportPDF(DateTime? startDate, DateTime? endDate, string searchQuery)
        {
            DateTime today = DateTime.Today;

            // Bước 1: Đảm bảo startDate và endDate luôn có giá trị (logic lọc mặc định)
            if (!startDate.HasValue) { startDate = new DateTime(today.Year, today.Month, 1); }
            if (!endDate.HasValue) { endDate = today; }

            // Bước 2: QUAN TRỌNG! Gán ViewBags tại đây để View BaoCaoPDF.cshtml sử dụng
            ViewBag.StartDate = startDate.Value;
            ViewBag.EndDate = endDate.Value;

            // Bước 3: Lấy dữ liệu đã lọc (cũng cần fix lỗi CS0266 ở hàm này)
            var data = GetFilteredData(startDate, endDate, searchQuery);

            // Bước 4: Gọi Rotativa
            return new Rotativa.ViewAsPdf("BaoCaoPDF", data)
            {
                FileName = $"BaoCaoDoanhThuPDF_{DateTime.Now.ToString("yyyyMMdd")}.pdf",
                PageOrientation = Rotativa.Options.Orientation.Landscape,
                PageSize = Rotativa.Options.Size.A4
            };
        }

        public ActionResult TimTheoDoanhThu(string macb)
        {
            var doanhthu = db.THONGKE_DOANHTHU.FirstOrDefault(cb => cb.MACB == macb);
            if (doanhthu != null)
            {
                return View("ThongKe", new List<THONGKE_DOANHTHU> { doanhthu });
            }
            else
            {
                ViewBag.Message = "Không tìm thấy chuyến bay với Mã Chuyến Bay: " + macb;
                return View("ThongKe", new List<THONGKE_DOANHTHU>());
            }
        }

        // ======================================================
        // STATISTICS ACTIONS USING SQL OBJECTS (Lines 850-981 from QLMayBay.sql)
        // ======================================================

        /// <summary>
        /// Display customer statistics by country
        /// Uses SQL Function: fn_ThongKeKhachTheoQuocGia() (Lines 925-935 in QLMayBay.sql)
        /// </summary>
        public ActionResult ThongKeQuocGia()
        {
            try
            {
                // Call SQL function to get customer count by country
                var result = db.Database.SqlQuery<ThongKeQuocGiaViewModel>(
                    "SELECT * FROM fn_ThongKeKhachTheoQuocGia()"
                ).ToList();

                return View(result);
            }
            catch (Exception ex)
            {
                ViewBag.Error = "Lỗi khi tải thống kê quốc gia: " + ex.Message;
                return View(new List<ThongKeQuocGiaViewModel>());
            }
        }

        /// <summary>
        /// Display revenue statistics by flight using cursor
        /// Uses SQL Stored Procedure: sp_ThongKeDoanhThuTheoChuyen (Wrapper for cursor lines 950-978)
        /// </summary>
        public ActionResult ThongKeDoanhThuTheoChuyen()
        {
            try
            {
                // Call stored procedure that uses cursor to iterate through flights
                var result = db.Database.SqlQuery<DoanhThuChuyenBayViewModel>(
                    "EXEC sp_ThongKeDoanhThuTheoChuyen"
                ).ToList();

                return View(result);
            }
            catch (Exception ex)
            {
                ViewBag.Error = "Lỗi khi tải thống kê doanh thu: " + ex.Message;
                return View(new List<DoanhThuChuyenBayViewModel>());
            }
        }

        /// <summary>
        /// Calculate total revenue for a specific month
        /// Uses SQL Stored Procedure: sp_TinhTongDoanhThu_Thang (Lines 902-916 in QLMayBay.sql)
        /// </summary>
        public ActionResult ThongKeTheoThang(int? thang, int? nam)
        {
            // Default to current month if not specified
            DateTime today = DateTime.Today;
            int selectedMonth = thang ?? today.Month;
            int selectedYear = nam ?? today.Year;

            try
            {
                // Prepare parameters for stored procedure
                var thangParam = new SqlParameter("@Thang", selectedMonth);
                var namParam = new SqlParameter("@Nam", selectedYear);
                var tongDoanhThuParam = new SqlParameter("@TongDoanhThu", SqlDbType.Money)
                {
                    Direction = ParameterDirection.Output
                };

                // Execute stored procedure with OUTPUT parameter
                db.Database.ExecuteSqlCommand(
                    "EXEC sp_TinhTongDoanhThu_Thang @Thang, @Nam, @TongDoanhThu OUTPUT",
                    thangParam, namParam, tongDoanhThuParam
                );

                // Get the output value
                decimal tongDoanhThu = tongDoanhThuParam.Value != DBNull.Value 
                    ? (decimal)tongDoanhThuParam.Value 
                    : 0M;

                // Pass data to view
                ViewBag.Thang = selectedMonth;
                ViewBag.Nam = selectedYear;
                ViewBag.TongDoanhThu = tongDoanhThu;

                return View();
            }
            catch (Exception ex)
            {
                ViewBag.Error = "Lỗi khi tính doanh thu tháng: " + ex.Message;
                ViewBag.Thang = selectedMonth;
                ViewBag.Nam = selectedYear;
                ViewBag.TongDoanhThu = 0M;
                return View();
            }
        }

        // ======================================================
        // END OF STATISTICS ACTIONS
        // ======================================================

        public ActionResult QLChuyenBay()
        {
            if (Session["AdminUser"] == null) return RedirectToAction("DangNhap", "User");
            // Include("MAYBAY") để load thông tin tên máy bay
            var flights = db.CHUYENBAYs.Include("MAYBAY").ToList();

            // Lấy danh sách máy bay để đổ vào Dropdown trong Modal
            ViewBag.ListMayBay = db.MAYBAYs.ToList();
            ViewBag.ListSanBay = db.SANBAYs.ToList();

            return View(flights);
        }
        public string NewIdChuyenBay()
        {
            var lastCB = db.CHUYENBAYs
                .Where(x => x.MACB.StartsWith("CB"))
                .OrderByDescending(x => x.MACB.Length)
                .ThenByDescending(x => x.MACB)
                .FirstOrDefault();

            int nextNumber = 1;
            if (lastCB != null)
            {
                // Lấy phần số sau chữ "CB"
                string numPart = lastCB.MACB.Substring(2);
                if (int.TryParse(numPart, out int num))
                {
                    nextNumber = num + 1;
                }
            }
            return "CB" + nextNumber.ToString("D3");
        }
        public ActionResult ThemChuyenBay(string MAMB, string TRANGTHAI, DateTime GIOCATCANH, DateTime GIOHACANH, string SBDI, string SBDEN)
        {
            try
            {
                // TỰ ĐỘNG SINH MÃ Ở ĐÂY
                string MACB = NewIdChuyenBay();

                // A. Tạo Chuyến Bay
                CHUYENBAY cb = new CHUYENBAY();
                cb.MACB = MACB;
                cb.MAMB = MAMB;
                cb.TRANGTHAI = TRANGTHAI;
                db.CHUYENBAYs.Add(cb);

                // B. Tạo Lộ Trình
                string maLT = "LT" + DateTime.Now.Ticks.ToString().Substring(12);

                LOTRINH lt = new LOTRINH();
                lt.MALT = maLT;
                lt.MACB = MACB;
                lt.GIOCATCANH = GIOCATCANH;
                lt.GIOHACANH = GIOHACANH;
                lt.SBDI = SBDI;
                lt.SBDEN = SBDEN;

                // Gán cứng sân bay (hoặc bạn thêm Dropdown chọn sân bay ở View sau này)
                lt.SBDI = "SB01";
                lt.SBDEN = "SB02";

                db.LOTRINHs.Add(lt);
                db.SaveChanges();
            }
            catch (Exception ex)
            {
                // Có thể ghi log lỗi tại đây
                ViewBag.Error = "Lỗi thêm mới: " + ex.Message;
            }

            return RedirectToAction("QLChuyenBay");
        }
        public ActionResult TimTheoMACB(string macb)
        {
            var flight = db.CHUYENBAYs.FirstOrDefault(cb => cb.MACB == macb);
            if (flight != null)
            {
                return View("QLChuyenBay", new List<CHUYENBAY> { flight });
            }
            else
            {
                ViewBag.Message = "Không tìm thấy chuyến bay với Mã Chuyến Bay: " + macb;
                return View("QLChuyenBay", new List<CHUYENBAY>());
            }
        }
        public ActionResult SuaChuyenBay(string MACB, string MAMB, string TRANGTHAI, string GIOCATCANH, string GIOHACANH, string SBDI, string SBDEN)
        {
            if (string.IsNullOrEmpty(MACB))
            {
                ViewBag.Error = "Mã chuyến bay không hợp lệ";
                return RedirectToAction("QLChuyenBay");
            }

            using (var transaction = db.Database.BeginTransaction())
            {
                try
                {
                    // 1. Cập nhật bảng CHUYENBAY
                    var cb = db.CHUYENBAYs.FirstOrDefault(x => x.MACB == MACB);
                    if (cb != null)
                    {
                        cb.MAMB = MAMB;
                        cb.TRANGTHAI = TRANGTHAI;
                        db.Entry(cb).State = EntityState.Modified;
                    }
                    else
                    {
                        ViewBag.Error = "Không tìm thấy chuyến bay!";
                        return RedirectToAction("QLChuyenBay");
                    }

                    // 2. Cập nhật bảng LOTRINH
                    var lt = db.LOTRINHs.FirstOrDefault(x => x.MACB == MACB);

                    // Ép kiểu chuỗi ngày giờ từ Form về DateTime an toàn
                    DateTime dtCatCanh = DateTime.Parse(GIOCATCANH);
                    DateTime dtHaCanh = DateTime.Parse(GIOHACANH);

                    if (lt != null)
                    {
                        lt.GIOCATCANH = dtCatCanh;
                        lt.GIOHACANH = dtHaCanh;

                        if (!string.IsNullOrEmpty(SBDI)) lt.SBDI = SBDI;
                        if (!string.IsNullOrEmpty(SBDEN)) lt.SBDEN = SBDEN;

                        db.Entry(lt).State = EntityState.Modified;
                    }
                    else
                    {
                        // Tạo lộ trình mới nếu chưa có
                        var newLt = new LOTRINH
                        {
                            MALT = "LT" + DateTime.Now.Ticks.ToString().Substring(12),
                            MACB = MACB,
                            GIOCATCANH = dtCatCanh,
                            GIOHACANH = dtHaCanh,
                            SBDI = SBDI,
                            SBDEN = SBDEN
                        };
                        db.LOTRINHs.Add(newLt);
                    }

                    db.SaveChanges();
                    transaction.Commit();
                    TempData["Success"] = "Cập nhật chuyến bay thành công!";
                }
                catch (Exception ex)
                {
                    transaction.Rollback();
                    TempData["Error"] = "Lỗi cập nhật: " + ex.Message;
                }
            }

            return RedirectToAction("QLChuyenBay");
        }
        [PhanQuyenAdmin("CV09", "CV05")]
        public ActionResult CapNhatTrangThaiBay()
        {
            try
            {
                // Gọi Cursor cập nhật
                var rowsAffected = db.Database.SqlQuery<int>("EXEC sp_UpdateFlightStatus_Cursor").FirstOrDefault();

                TempData["Success"] = $"Đã cập nhật trạng thái cho {rowsAffected} chuyến bay dựa trên giờ thực tế!";
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Lỗi cập nhật: " + ex.Message;
            }

            // Quay lại trang quản lý chuyến bay để thấy kết quả ngay
            return RedirectToAction("QLChuyenBay");
        }
        public ActionResult XoaChuyenBay(string id)
        {
            // 1. Tìm chuyến bay
            var cb = db.CHUYENBAYs.FirstOrDefault(x => x.MACB == id);
            if (cb == null)
            {
                TempData["Error"] = "Không tìm thấy chuyến bay!";
                return RedirectToAction("QLChuyenBay");
            }

            // 2. KIỂM TRA RÀNG BUỘC (Quan trọng)
            // Nếu đã có vé bán, không cho xóa
            if (db.VEMAYBAYs.Any(v => v.MACB == id))
            {
                TempData["Error"] = $"Không thể xóa chuyến {id} vì đã có vé được bán!";
                return RedirectToAction("QLChuyenBay");
            }

            // Nếu đang nằm trong giỏ hàng của ai đó
            if (db.GIOHANG_CHITIET.Any(gh => gh.MACB == id))
            {
                TempData["Error"] = $"Không thể xóa chuyến {id} vì đang nằm trong giỏ hàng của khách!";
                return RedirectToAction("QLChuyenBay");
            }

            // 3. XÓA CÁC BẢNG PHỤ TRƯỚC (Do ràng buộc khóa ngoại)

            // Xóa Lộ trình (Bắt buộc vì quan hệ 1-1 hoặc 1-n)
            var loTrinhs = db.LOTRINHs.Where(lt => lt.MACB == id).ToList();
            db.LOTRINHs.RemoveRange(loTrinhs);

            // Xóa Giá hạng ghế
            var giaGhes = db.HANGGHE_GIA.Where(h => h.MACB == id).ToList();
            db.HANGGHE_GIA.RemoveRange(giaGhes);

            // Xóa Hành lý quy định (nếu có)
            var hanhlys = db.HANHLies.Where(h => h.MACB == id).ToList();
            db.HANHLies.RemoveRange(hanhlys);

            // 4. XÓA CHUYẾN BAY CHÍNH
            db.CHUYENBAYs.Remove(cb);
            db.SaveChanges();

            TempData["Success"] = "Xóa chuyến bay thành công!";

            return RedirectToAction("QLChuyenBay");
        }
        [HttpPost]
        public ActionResult CapNhatLogoHang(string tenHang, HttpPostedFileBase logoFile)
        {
            if (string.IsNullOrEmpty(tenHang) || logoFile == null || logoFile.ContentLength <= 0)
            {
                TempData["Error"] = "Vui lòng chọn hãng và file ảnh hợp lệ!";
                return RedirectToAction("QLChuyenBay");
            }

            try
            {
                string ext = Path.GetExtension(logoFile.FileName);
                string cleanName = tenHang.Replace(" ", "");
                string fileName = cleanName + ext;

                // 2. Đường dẫn lưu
                string folderPath = Server.MapPath("~/Content/Images/Airline/");
                if (!Directory.Exists(folderPath))
                {
                    Directory.CreateDirectory(folderPath);
                }
                string[] existingFiles = Directory.GetFiles(folderPath, cleanName + ".*");
                foreach (var f in existingFiles)
                {
                    System.IO.File.Delete(f);
                }

                // 4. Lưu file mới
                string path = Path.Combine(folderPath, fileName);
                logoFile.SaveAs(path);

                TempData["Success"] = $"Đã cập nhật logo cho hãng {tenHang}!";
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Lỗi cập nhật logo: " + ex.Message;
            }

            return RedirectToAction("QLChuyenBay");
        }
        public ActionResult QLVe(string selectedId = null)
        {
            var listData = new List<QuanLyVe>();

            // 1. LẤY VÉ ĐÃ THANH TOÁN (CÓ TRUY VẤN TÊN HÀNH KHÁCH THỰC TẾ)
            var paidTickets = (from ctv in db.CHITIETVEs
                               join pdv in db.PHIEUDATVEs on ctv.MAPHIEU equals pdv.MAPHIEU
                               join ve in db.VEMAYBAYs on ctv.MAVE equals ve.MAVE
                               join ghe in db.GHEs on ve.MAGHE equals ghe.MAGHE
                               join kh_dat in db.KHACHHANGs on pdv.MAKH equals kh_dat.MAKH
                               join ci in db.CHECKINs on ctv.MAVE equals ci.MAVE into ciGroup
                               from ci in ciGroup.DefaultIfEmpty()
                               let infoHanhKhach = db.GIOHANG_HANHKHACH
                                                    .Where(h => h.MAGH == pdv.MAGH
                                                             && h.MACB == ve.MACB
                                                             && h.SOGHE == ghe.TENGHE)
                                                    .Select(h => new { h.TENHANHKHACH, h.EMAIL, h.SDT })
                                                    .FirstOrDefault()
                               select new QuanLyVe
                               {
                                   MAVE = ctv.MAVE,
                                   MAPHIEU = ctv.MAPHIEU,

                                   // 1. Ưu tiên Tên người bay thực tế
                                   TENKH = infoHanhKhach != null ? infoHanhKhach.TENHANHKHACH : kh_dat.TENKH,

                                   // 2. Ưu tiên Email người bay thực tế
                                   EMAIL = infoHanhKhach.EMAIL,
                                   SDT = infoHanhKhach.SDT,
                                   TENNV = pdv.MANV ?? "Online",
                                   NGAYDAT = pdv.NGLAP ?? DateTime.Now,
                                   GIATIEN = (int)(ctv.GIATIEN ?? 0),
                                   TRANGTHAI = "Đã thanh toán",
                                   TRANGTHAIVE = ci != null ? ci.TRANGTHAI : "Chưa check-in"
                               }).OrderByDescending(x => x.NGAYDAT).ToList();

            listData.AddRange(paidTickets);

            // =================================================================================
            // 2. LẤY VÉ CHƯA THANH TOÁN / ĐANG CHỜ (Dữ liệu từ GIOHANG)
            // =================================================================================
            var pendingCarts = db.GIOHANGs
                .Where(g => g.TRANGTHAI != "Đã Thanh Toán" && g.TRANGTHAI != "Đã thanh toán")
                .OrderByDescending(g => g.NGAYTAO)
                .ToList();

            foreach (var gh in pendingCarts)
            {
                var kh = db.KHACHHANGs.FirstOrDefault(k => k.MAKH == gh.MAKH);

                // Lấy chi tiết các vé trong giỏ (vì 1 giỏ có thể mua nhiều vé)
                var cartDetails = db.GIOHANG_CHITIET.Where(d => d.MAGH == gh.MAGH).ToList();

                foreach (var item in cartDetails)
                {
                    // Kiểm tra xem vé còn hạn giữ chỗ không
                    string trangThaiHienThi = "Chờ xử lý";
                    if (item.THOIGIANGIU < DateTime.Now)
                    {
                        trangThaiHienThi = "Hết hạn/Hủy";
                    }

                    // Tạo dòng dữ liệu ảo để hiển thị chung bảng
                    var row = new QuanLyVe
                    {
                        // Chưa có Mã Vé thật -> Hiển thị gạch ngang hoặc ghi chú
                        MAVE = "---",

                        // Chưa có Mã Phiếu -> Hiển thị Mã Giỏ Hàng để Admin đối chiếu
                        MAPHIEU = gh.MAGH + " (Giỏ)",

                        TENKH = kh?.TENKH ?? "Khách vãng lai",
                        EMAIL = kh?.EMAIL ?? "N/A",
                        TENNV = "Hệ thống", // Chưa có nhân viên xử lý
                        NGAYDAT = gh.NGAYTAO ?? DateTime.Now,

                        // Giá tiền trong giỏ là tổng, ta chia hoặc lấy theo item
                        GIATIEN = (int)(item.GIATIEN ?? 0),

                        TRANGTHAI = trangThaiHienThi,
                        TRANGTHAIVE = "N/A" // Chưa thanh toán thì không có trạng thái check-in
                    };

                    // Chỉ thêm vào danh sách nếu bạn muốn Admin thấy cả vé Hết hạn, 
                    // hoặc lọc chỉ lấy "Chờ xử lý" tùy ý. Ở đây mình lấy hết.
                    listData.Add(row);
                }
            }

            // =================================================================================
            // 3. XỬ LÝ MODAL CHI TIẾT (Nếu Admin chọn 1 dòng cụ thể)
            // =================================================================================
            TicketDetailAdminViewModel detail = null;
            if (!string.IsNullOrEmpty(selectedId) && selectedId != "---")
            {
                // Tìm vé thật trong VEMAYBAY
                var realTicket = db.VEMAYBAYs.FirstOrDefault(v => v.MAVE == selectedId);
                if (realTicket != null)
                {
                    detail = GetPaidTicketDetail(realTicket);
                }
            }

            var model = new QLVeViewModel
            {
                DanhSachVe = listData,
                VeDangChon = detail
            };

            return View(model);
        }
        // Action xử lý Check-in (Reload lại trang QLVe với tham số selectedId)
        public ActionResult ToggleCheckIn(string id)
        {
            var checkIn = db.CHECKINs.FirstOrDefault(ci => ci.MAVE == id);
            if (checkIn == null)
            {
                // Tạo mới
                checkIn = new CHECKIN();
                checkIn.MACHECKIN = "CI" + DateTime.Now.Ticks.ToString().Substring(12);
                checkIn.MAVE = id;
                var ve = db.VEMAYBAYs.Find(id);
                var ctv = db.CHITIETVEs.FirstOrDefault(c => c.MAVE == id);
                var pdv = db.PHIEUDATVEs.FirstOrDefault(p => p.MAPHIEU == ctv.MAPHIEU);
                checkIn.MAKH = pdv.MAKH;
                checkIn.MACB = ve.MACB;
                checkIn.TRANGTHAI = "Đã check-in";
                checkIn.THOIGIAN_CHECKIN = DateTime.Now;
                db.CHECKINs.Add(checkIn);
            }
            else
            {
                // Đổi trạng thái
                if (checkIn.TRANGTHAI == "Đã check-in")
                {
                    checkIn.TRANGTHAI = "Chưa check-in";
                    checkIn.THOIGIAN_CHECKIN = null;
                }
                else
                {
                    checkIn.TRANGTHAI = "Đã check-in";
                    checkIn.THOIGIAN_CHECKIN = DateTime.Now;
                }
            }
            db.SaveChanges();

            // QUAN TRỌNG: Quay lại trang QLVe và VẪN GIỮ Modal mở (bằng cách truyền lại id)
            return RedirectToAction("QLVe", new { selectedId = id });
        }
        private TicketDetailAdminViewModel GetPaidTicketDetail(VEMAYBAY ve)
        {
            var cb = db.CHUYENBAYs.FirstOrDefault(c => c.MACB == ve.MACB);
            var lt = db.LOTRINHs.FirstOrDefault(l => l.MACB == ve.MACB);
            var sb1 = db.SANBAYs.FirstOrDefault(s => s.MASB == lt.SBDI);
            var sb2 = db.SANBAYs.FirstOrDefault(s => s.MASB == lt.SBDEN);

            // Truy ngược từ Vé -> Chi Tiết Vé -> Phiếu Đặt -> Khách Hàng
            var ctv = db.CHITIETVEs.FirstOrDefault(c => c.MAVE == ve.MAVE);
            var pdv = db.PHIEUDATVEs.FirstOrDefault(p => p.MAPHIEU == ctv.MAPHIEU);
            var kh = db.KHACHHANGs.FirstOrDefault(k => k.MAKH == pdv.MAKH);

            var ci = db.CHECKINs.FirstOrDefault(c => c.MAVE == ve.MAVE);
            var seat = db.GHEs.FirstOrDefault(g => g.MAGHE == ve.MAGHE);
            var seatClass = db.HANGGHE_GIA.FirstOrDefault(h => h.MAHG == ve.MAHG);

            var hanhKhachBay = db.GIOHANG_HANHKHACH
                .FirstOrDefault(hk => hk.MAGH == pdv.MAGH && hk.MACB == ve.MACB && hk.SOGHE == seat.TENGHE);

            return new TicketDetailAdminViewModel
            {
                MaVe = ve.MAVE,
                TenKhach = hanhKhachBay?.TENHANHKHACH ?? kh?.TENKH, // Ưu tiên tên người bay, nếu không có lấy tên người đặt
                Email = hanhKhachBay?.EMAIL,
                Sdt = hanhKhachBay?.SDT,
                MaCB = ve.MACB,
                HangBay = db.MAYBAYs.FirstOrDefault(m => m.MAMB == cb.MAMB)?.HANG,
                SanBayDi = sb1?.TENSB,
                SanBayDen = sb2?.TENSB,
                NgayBay = lt?.GIOCATCANH.ToString("dd/MM/yyyy"),
                GioBay = lt?.GIOCATCANH.ToString("HH:mm"),
                SoGhe = seat?.TENGHE,
                HangGhe = seatClass?.HANGGHE,
                TrangThaiCheckIn = ci?.TRANGTHAI ?? "Chưa check-in"
            };
        }
        public ActionResult TimTheoMAVE(string mave)
        {
            var vemb = db.CHITIETVEs
                         .Where(ve => string.IsNullOrEmpty(mave) || ve.MAVE == mave)
                         .Select(x => new QuanLyVe
                         {
                             MAVE = x.MAVE,
                             MAPHIEU = x.MAPHIEU,
                             TENKH = x.PHIEUDATVE.KHACHHANG.TENKH,
                             EMAIL = x.PHIEUDATVE.KHACHHANG.EMAIL,
                             TENNV = x.PHIEUDATVE.NHANVIEN.TENNV,
                             GIATIEN = x.GIATIEN.HasValue ? (int)x.GIATIEN.Value : 0,
                             NGAYDAT = x.NGAYDAT,
                             TRANGTHAI = x.PHIEUDATVE.TRANGTHAI.ToString(),
                             TRANGTHAIVE = x.PHIEUDATVE.TRANGTHAI.ToString(),
                         })
                         .ToList();

            if (!vemb.Any() && !string.IsNullOrEmpty(mave))
                ViewBag.Message = "Không tìm thấy mã: " + mave;

            return View("QLVe", vemb);
        }

        [PhanQuyenAdmin("CV09", "CV05")]
        public ActionResult QLPerson(string selectedMakh = null)
        {
            var model = new QLPersonViewModel();

            // 1. Lấy danh sách Nhân viên (Giữ nguyên logic cũ)
            model.ListNhanVien = db.NHANVIENs.ToList();

            // 2. Lấy danh sách Khách hàng + Đếm số vé
            model.ListKhachHang = (from kh in db.KHACHHANGs
                                       // Join để đếm số phiếu đã thanh toán
                                   let soVe = (from p in db.PHIEUDATVEs
                                               join ct in db.CHITIETVEs on p.MAPHIEU equals ct.MAPHIEU
                                               where p.MAKH == kh.MAKH && p.TRANGTHAI.Contains("Thanh Toán")
                                               select ct).Count()
                                   select new KhachHangViewModel
                                   {
                                       MAKH = kh.MAKH,
                                       TENKH = kh.TENKH,
                                       EMAIL = kh.EMAIL,
                                       QUOCGIA = kh.QUOCGIA,
                                       SoVeDaDat = soVe
                                   }).ToList();

            // 3. Xử lý Lịch sử vé (Nếu người dùng chọn xem 1 khách)
            if (!string.IsNullOrEmpty(selectedMakh))
            {
                var khach = db.KHACHHANGs.Find(selectedMakh);
                if (khach != null)
                {
                    var historyList = (from pdv in db.PHIEUDATVEs
                                       join ctv in db.CHITIETVEs on pdv.MAPHIEU equals ctv.MAPHIEU
                                       join ve in db.VEMAYBAYs on ctv.MAVE equals ve.MAVE
                                       join cb in db.CHUYENBAYs on ve.MACB equals cb.MACB
                                       join lt in db.LOTRINHs on cb.MACB equals lt.MACB
                                       join sbDi in db.SANBAYs on lt.SBDI equals sbDi.MASB
                                       join sbDen in db.SANBAYs on lt.SBDEN equals sbDen.MASB
                                       where pdv.MAKH == selectedMakh
                                       orderby pdv.NGLAP descending
                                       select new LichSuVeDTO
                                       {
                                           MaVe = ctv.MAVE,
                                           // Chuyển đổi ngày tháng sang string ở Client hoặc dùng .AsEnumerable() trước
                                           // Ở đây để đơn giản ta lấy dữ liệu thô trước
                                           NgayDat = "", // Sẽ gán sau
                                           MaCB = cb.MACB,
                                           HanhTrinh = sbDi.THANHPHO + " -> " + sbDen.THANHPHO,
                                           NgayBay = "", // Sẽ gán sau
                                           GiaTien = (int)ctv.GIATIEN,
                                           TrangThai = pdv.TRANGTHAI,

                                           // Lấy dữ liệu gốc để format sau
                                           _NgayDatGoc = pdv.NGLAP,
                                           _NgayBayGoc = lt.GIOCATCANH
                                       }).ToList();

                    // Format lại ngày tháng (vì LINQ to Entity không hỗ trợ .ToString("dd/MM") trực tiếp)
                    foreach (var item in historyList)
                    {
                        item.NgayDat = item._NgayDatGoc?.ToString("dd/MM/yyyy");
                        item.NgayBay = item._NgayBayGoc.ToString("dd/MM/yyyy HH:mm");
                    }

                    model.SelectedHistory = new CustomerHistoryViewModel
                    {
                        TenKhachHang = khach.TENKH,
                        DanhSachVe = historyList
                    };
                }
            }

            // Giữ lại ViewBag để tránh lỗi nếu View cũ còn dùng (tùy chọn)
            ViewBag.NhanVien = model.ListNhanVien;
            ViewBag.KhachHang = db.KHACHHANGs.ToList();

            return View(model);
        }
        public ActionResult TimTheoMANV(string manv)
        {
            ViewBag.KhachHang = db.KHACHHANGs.ToList();


            var member = db.NHANVIENs.Where(nv => nv.MANV == manv).ToList();

            if (member.Any())
            {
                ViewBag.NhanVien = member;
            }
            else
            {
                ViewBag.NhanVien = new List<NHANVIEN>();
                ViewBag.Message = "Không tìm thấy nhân viên với mã: " + manv;
            }

            return View("QLPerson");
        }
        [HttpPost]
        [PhanQuyenAdmin("CV09", "CV05")]
        public ActionResult ThemNhanVien(NHANVIEN nv)
        {
            if (ModelState.IsValid)
            {
                db.NHANVIENs.Add(nv);
                db.SaveChanges();
            }

            return RedirectToAction("QLPerson");
        }
        [PhanQuyenAdmin("CV09", "CV05")]
        public ActionResult XoaNhanVien(string manv)
        {
            try
            {
                var adminUser = Session["AdminUser"] as NHANVIEN;
                string currentAdminId = adminUser.MANV;
                // Logic: Chuyển toàn bộ vé của nhân viên bị xóa sang cho Admin đang đăng nhập
                string sql = "EXEC sp_DeleteEmployee_SafeTransaction @p0, @p1";

                db.Database.ExecuteSqlCommand(sql, manv, currentAdminId);

                TempData["Success"] = $"Đã xóa nhân viên {manv} và chuyển giao dữ liệu thành công!";
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Lỗi xóa: " + ex.Message;
            }

            return RedirectToAction("QLPerson");
        }
        [PhanQuyenAdmin("CV09", "CV05")]
        public ActionResult SuaNhanVien(string manv)
        {
            var nv = db.NHANVIENs.Find(manv);
            if (nv == null)
            {
                return HttpNotFound();
            }

            ViewBag.ChucVu = db.CHUCVUs.ToList();

            return View(nv);
        }
        [HttpPost]
        [PhanQuyenAdmin("CV09", "CV05")]
        public ActionResult SuaNhanVien(NHANVIEN model)
        {
            ViewBag.ChucVu = db.CHUCVUs.ToList(); // Load lại dropdown nếu lỗi

            if (ModelState.IsValid)
            {
                try
                {
                    // Sử dụng câu lệnh SQL trực tiếp để kích hoạt Trigger và bắt lỗi Exception chuẩn nhất
                    // (Giống hệt cách hoạt động của hàm Xóa bạn đã làm)
                    string sql = "UPDATE NHANVIEN SET TENNV = @p0, SDT = @p1, MACV = @p2 WHERE MANV = @p3";

                    // Thực thi lệnh
                    db.Database.ExecuteSqlCommand(sql,
                        model.TENNV,
                        model.SDT,
                        model.MACV,
                        model.MANV
                    );

                    TempData["Success"] = $"Cập nhật nhân viên {model.MANV} thành công!";
                    return RedirectToAction("QLPerson");
                }
                catch (Exception ex)
                {
                    // Bắt lỗi từ RAISERROR trong Trigger
                    // ex.Message sẽ chứa dòng: "LỖI: Không thể xóa hoặc giáng chức Giám đốc..."
                    TempData["Error"] = "Lỗi cập nhật: " + ex.Message;
                }
            }

            return View(model);
        }
        // Trang Backup/Restore
        [PhanQuyenAdmin("CV09", "CV05")]
        public ActionResult CaiDat()
        {
            return View();
        }

        [HttpPost]
        [PhanQuyenAdmin("CV09", "CV05")]
        public ActionResult BackupDatabase(string backupName, string backupType)
        {
            try
            {
                string folderPath = @"D:\Backups_QLMayBay\";

                if (!Directory.Exists(folderPath))
                {
                    Directory.CreateDirectory(folderPath);
                }
                string timeStamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");
                string suffix = "";
                string extension = ".bak";
                string messageType = "";
                // Xử lý loại backup dựa trên input từ View
                switch (backupType)
                {
                    case "full":
                        suffix = "FULL";
                        messageType = "Toàn bộ (Full)";
                        break;
                    case "diff":
                        suffix = "DIFF";
                        messageType = "Khác biệt (Diff)";
                        break;
                    case "log":
                        suffix = "LOG";
                        extension = ".trn";
                        messageType = "Nhật ký (Log)";
                        break;
                    default:
                        // Mặc định là Full nếu không chọn gì
                        suffix = "FULL";
                        backupType = "full";
                        messageType = "Toàn bộ (Full)";
                        break;
                }
                string customName = string.IsNullOrEmpty(backupName) ? timeStamp : backupName + "_" + timeStamp;
                string fileName = $"QLMayBay_{suffix}_{customName}{extension}";
                string fullPath = Path.Combine(folderPath, fileName);
                string sqlCommand = "EXEC sp_BackupDatabase @p0, @p1";
                db.Database.CommandTimeout = 300;
                // Thực thi lệnh
                db.Database.ExecuteSqlCommand(TransactionalBehavior.DoNotEnsureTransaction, sqlCommand, fullPath, backupType);
                TempData["Message"] = $"Sao lưu {messageType} thành công!\nFile lưu tại: {fullPath}";
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Lỗi khi sao lưu: " + ex.Message;
            }
            // Quay lại trang Cài đặt
            return RedirectToAction("CaiDat");
        }

        // Action: RESTORE DATABASE
        [HttpPost]
        [PhanQuyenAdmin("CV09", "CV05")]
        public ActionResult RestoreDatabase(HttpPostedFileBase backupFile)
        {
            if (backupFile != null && backupFile.ContentLength > 0)
            {
                try
                {
                    string dbName = "QUANLYMAYBAY";

                    // 1. Lưu file .bak tạm thời lên server
                    string fileName = Path.GetFileName(backupFile.FileName);
                    string savePath = Server.MapPath("~/App_Data/" + fileName);
                    backupFile.SaveAs(savePath);

                    // 2. Tạo câu lệnh SQL Restore
                    // QUAN TRỌNG: Phải đưa DB về chế độ SINGLE_USER để ngắt các kết nối khác trước khi restore
                    string query = $@"
                USE master;
                ALTER DATABASE [{dbName}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
                RESTORE DATABASE [{dbName}] FROM DISK = '{savePath}' WITH REPLACE;
                ALTER DATABASE [{dbName}] SET MULTI_USER;
            ";

                    // 3. Thực thi
                    db.Database.ExecuteSqlCommand(System.Data.Entity.TransactionalBehavior.DoNotEnsureTransaction, query);

                    TempData["Message"] = "Phục hồi dữ liệu thành công! Hệ thống đã trở lại trạng thái cũ.";
                }
                catch (Exception ex)
                {
                    TempData["Message"] = "Lỗi phục hồi: " + ex.Message;
                }
            }
            else
            {
                TempData["Message"] = "Vui lòng chọn file backup (.bak) để phục hồi.";
            }

            return RedirectToAction("CaiDat");
        }
        public ActionResult ApiFlight()
        {
            return View();
        }

    }
}