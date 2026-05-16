using Microsoft.Ajax.Utilities;
using QuanLyMayBay.Models;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Data.Entity;
using System.Data.Entity.Migrations;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Web.UI.WebControls;


namespace QuanLyMayBay.Controllers
{
    public class UserController : Controller
    {
        //Data
        QUANLYMAYBAYEntities db = new QUANLYMAYBAYEntities();
        // GET: User
        // Trang giới thiệu
        public ActionResult GioiThieu()
        {
            return View();
        }
        //Trang Đăng Ký
        public ActionResult DangKy()
        {
            return View();
        }
        [HttpPost]
        public ActionResult DangKyThanhCong(FormCollection form)
        {
            KHACHHANG kh = new KHACHHANG()
            {
                MAKH = MaKH(),
                TENKH = form["fullName"],
                EMAIL = form["email"],
                MATKHAU = form["password"],
                SDT = form["phone"]
            };
            db.KHACHHANGs.Add(kh);
            db.SaveChanges();
            return RedirectToAction("DangNhap");
        }
        // Dùng để tìm mã khách hàng
        public string MaKH()
        {
            const string prefix = "KH";
            var lastKH = db.KHACHHANGs
                .Where(k => k.MAKH.StartsWith(prefix))
                .OrderByDescending(k => k.MAKH.Length)
                .ThenByDescending(k => k.MAKH)
                .FirstOrDefault();
            if (lastKH == null) return prefix + "001";

            string numStr = lastKH.MAKH.Substring(prefix.Length);
            if (int.TryParse(numStr, out int num))
            {
                int nextNum = num + 1;
                return prefix + nextNum.ToString("D3");
            }
            return prefix + "001";
        }

        //Trang Đăng Nhập
        public ActionResult DangNhap()
        {
            return View();
        }
        [HttpPost]
        public ActionResult DangNhapThanhCong(FormCollection form)
        {

            string Email = form["email"];
            string password = form["password"];
            Session["ErrorEmail"] = null;
            Session["ErrorPassword"] = null;
            KHACHHANG kh = db.KHACHHANGs.FirstOrDefault(x => x.EMAIL.Trim() == Email.Trim());
            if (kh == null)
            {
                Session["ErrorEmail"] = "Email không chính xác!";
                return RedirectToAction("DangNhap");
            }
            if (kh.MATKHAU.Trim() != password.Trim())
            {
                Session["Email"] = Email;
                Session["ErrorPassword"] = "Mật khẩu không chính xác!";
                return RedirectToAction("DangNhap");
            }


            Session["UserName"] = kh;
            return RedirectToAction("TrangChu");
        }

        public ActionResult DangXuat()
        {
            Session["UserName"] = null;
            return RedirectToAction("GioiThieu");
        }
        //Trang chủ
        public ActionResult TrangChu()
        {
            KHACHHANG kh = (KHACHHANG)Session["UserName"];
            var hangList = db.MAYBAYs.Select(m => m.HANG).Distinct().ToList();
            Session["Hang"] = hangList;

            if (kh != null)

            {
                string virtualPath = "~/Content/Images/User";
                string DirPath = Server.MapPath(virtualPath);
                string searchPattern = $"{kh.MAKH.Trim()}.*";
                string[] oldFiles = Directory.GetFiles(DirPath, searchPattern);
                if (oldFiles.Length > 0 && oldFiles[0] != null)
                {
                    Session["Image"] = Path.GetFileName(oldFiles[0]);
                }
                ViewBag.TenKH = kh.TENKH;
            }
            LoadChuyenBay();
            return View();
        }
        // Hồ sơ khách hàng
        public ActionResult HoSo()
        {
            return View((KHACHHANG)Session["UserName"]);
        }
        //Cập nhật hồ sơ
        [HttpPost]
        public ActionResult CapNhatHoSo(FormCollection form, HttpPostedFileBase Image)
        {
            KHACHHANG sessionKH = (KHACHHANG)Session["UserName"];
            var kh = db.KHACHHANGs.Find(sessionKH.MAKH);
            // Thực hiện thay đổi thông tin
            kh.TENKH = form["fullName"];
            kh.SDT = form["phone"];
            string ngSinh = form["birthDate"];

            if (ngSinh != string.Empty)

            {
                kh.NGSINH = DateTime.Parse(ngSinh);
            }
            kh.GTINH = form["gender"];
            kh.QUOCGIA = form["country"];
            kh.DIACHI = form["address"];
            db.Entry(kh).State = EntityState.Modified;
            db.SaveChanges();

            if (ModelState.IsValid && Image != null)
            {
                string virtualPath = "~/Content/Images/User";
                string DirPath = Server.MapPath(virtualPath);

                if (!Directory.Exists(DirPath))
                {
                    Directory.CreateDirectory(DirPath);
                }
                //Thực hiện xóa ảnh cũ 
                string searchPattern = $"{kh.MAKH.Trim()}.*";
                string[] oldFiles = Directory.GetFiles(DirPath, searchPattern);

                if (oldFiles != null)

                {
                    foreach (var oldFilePath in oldFiles)
                    {
                        System.IO.File.Delete(oldFilePath);

                    }
                }

                //Thực hiện thêm mới 1 ảnh
                string fileExtension = Path.GetExtension(Image.FileName);
                string newFileName = $"{kh.MAKH.Trim()}{fileExtension}";
                string filePath = Path.Combine(DirPath, newFileName);
                Image.SaveAs(filePath);
            }

            Session["UserName"] = kh;

            return RedirectToAction("HoSo");
        }
        // Đổi mật khẩu
        public ActionResult ChangePassword(FormCollection form)
        {
            KHACHHANG sessionKH = (KHACHHANG)Session["UserName"];
            var kh = db.KHACHHANGs.Find(sessionKH.MAKH);
            if (string.IsNullOrEmpty(form["currentPassword"]) || string.IsNullOrEmpty(form["newPassword"]) || string.IsNullOrEmpty(form["confirmPassword"]))
            {
                ViewBag.PasswordError = "Vui lòng nhập đầy đủ thông tin.";
                ViewBag.ShowPasswordModal = true;
                return View("HoSo", kh);
            }


            if (form["newPassword"].Length < 6)
            {
                ViewBag.PasswordError = "Mật khẩu mới phải có ít nhất 6 ký tự.";
                ViewBag.ShowPasswordModal = true;
                return View("HoSo", kh);
            }

            if (form["newPassword"] != form["confirmPassword"])
            {
                ViewBag.PasswordError = "Mật khẩu xác nhận không khớp.";
                ViewBag.ShowPasswordModal = true;
                return View("HoSo", kh);
            }

            // Kiểm tra mật khẩu hiện tại có đúng không
            if (kh.MATKHAU.Trim() != form["currentPassword"])
            {
                ViewBag.PasswordError = "Mật khẩu hiện tại không chính xác.";
                ViewBag.ShowPasswordModal = true;
                return View("HoSo", kh);
            }


            // Cập nhật mật khẩu mới
            kh.MATKHAU = form["newPassword"];
            db.Entry(kh).State = EntityState.Modified;
            db.SaveChanges();

            // Gửi thông báo thành công
            ViewBag.PasswordSuccess = "Đổi mật khẩu thành công!";

            return View("HoSo", kh);

        }
        [HttpPost]
        public ActionResult CapNhatHanhKhach(int soLuong, string maCB)
        {
            if (soLuong > 0)
            {
                Session["passenger"] = soLuong;
            }

            // Sau khi lưu xong, chuyển hướng sang trang chọn chỗ của chuyến bay đó
            return RedirectToAction("ChonCho", new { MaCB = maCB });
        }
        // Load chuyến bay
        public void LoadChuyenBay()
        {
            ListChuyenBayModel chuyenBayList = new ListChuyenBayModel();
            chuyenBayList.listCB = (from cb in db.CHUYENBAYs
                                    join mb in db.MAYBAYs on cb.MAMB equals mb.MAMB
                                    join lt in db.LOTRINHs on cb.MACB equals lt.MACB
                                    join sbDi in db.SANBAYs on lt.SBDI equals sbDi.MASB
                                    join sbDen in db.SANBAYs on lt.SBDEN equals sbDen.MASB
                                    join hgg in db.HANGGHE_GIA on cb.MACB equals hgg.MACB
                                    select new ChuyenBayModel()
                                    {
                                        MaCB = cb.MACB,
                                        Hang = mb.HANG,
                                        MaMB = cb.MAMB,
                                        DiemDi = sbDi.THANHPHO,
                                        DiemDen = sbDen.THANHPHO,
                                        Gia = (int)hgg.GIA_COSO,
                                        HangGhe = hgg.HANGGHE,
                                        GioCatCanh = lt.GIOCATCANH,
                                        GioHaCanh = lt.GIOHACANH
                                    }).ToList();
            Session["ListFull"] = chuyenBayList;
            Session["ListChuyenBay"] = chuyenBayList;
            Session["ListOld"] = chuyenBayList;
            Session["passenger"] = 0;
            Image(chuyenBayList);
        }
        // Trang đặt vé
        public ActionResult DatVe(string maKH, string maNV, string maGH)
        {
            try
            {
                // Gọi PROCEDURE
                db.Database.ExecuteSqlCommand(
                    "EXEC sp_DatVe @MaKH, @MaNV, @MAGH",
                    new SqlParameter("@MaKH", maKH),
                    new SqlParameter("@MaNV", maNV),
                    new SqlParameter("@MAGH", maGH)
                );

                ViewBag.Message = "Đặt vé thành công!";
            }
            catch (Exception ex)
            {
                ViewBag.Message = "Đặt vé thất bại: " + ex.Message;
            }
            ListChuyenBayModel chuyenBayList = Session["ListFull"] as ListChuyenBayModel;
            Image(chuyenBayList);
            Session["DiemDen"] = "";
            Session["DiemDi"] = "";
            return View(chuyenBayList.listCB);
        }
        [HttpPost]

        public ActionResult TimChuyen(FormCollection form)
        {
            var hangList = db.MAYBAYs.Select(m => m.HANG).Distinct().ToList();
            Session["Hang"] = hangList;

            string diemdi = "";
            string diemden = "";
            DateTime ngaydi = DateTime.Now;
            DateTime ngayve = ngaydi.AddDays(1);
            // Số lượng hành khách và loại chuyến
            Session["passenger"] = int.Parse(form["passenger"]);
            Session["trip-type"] = form["trip-type"];

            // === XỬ LÝ CHIỀU ĐI VÀ CHIỀU VỀ ===
            if ((string)Session["trip-type"] == "Khứ hồi")
            {
                // Lần đầu chọn chiều đi
                if (Session["round2"] == null || !(bool)Session["round2"])
                {
                    diemdi = form["from"];
                    diemden = form["to"];
                    ngaydi = DateTime.Parse(form["ngaydi"]);
                    ngayve = DateTime.Parse(form["ngayve"]);


                    Session["DiemDi"] = diemdi;
                    Session["DiemDen"] = diemden;
                    Session["NgayDi"] = ngaydi;
                    Session["NgayVe"] = ngayve;

                    Session["Chieu"] = "Chọn chuyến cho chiều đi";
                    Session["round2"] = true;
                }
            }
            else // Một chiều
            {
                diemdi = form["from"];
                diemden = form["to"];
                ngaydi = DateTime.Parse(form["ngaydi"]);

                Session["DiemDi"] = diemdi;
                Session["DiemDen"] = diemden;
                Session["NgayDi"] = ngaydi;
                Session["Chieu"] = "Chọn chuyến cho chiều đi";
                Session["round2"] = false;
            }

            SANBAY SBDI = db.SANBAYs.FirstOrDefault(x => x.THANHPHO == diemdi);
            SANBAY SBDen = db.SANBAYs.FirstOrDefault(x => x.THANHPHO == diemden);

            ListChuyenBayModel chuyenBayList = Session["ListFull"] as ListChuyenBayModel;
            ListChuyenBayModel LocCB = new ListChuyenBayModel();
            LocCB.listCB = chuyenBayList.listCB
                           .Where(x => x.GioCatCanh.Date == ngaydi.Date)
                           .ToList();

            // Lọc theo điểm đi và điểm đến
            if (SBDI != null) LocCB.listCB = LocCB.listCB.Where(x => x.DiemDi == SBDI.THANHPHO).ToList();
            if (SBDen != null) LocCB.listCB = LocCB.listCB.Where(x => x.DiemDen == SBDen.THANHPHO).ToList();

            // Gán hình ảnh hãng bay
            Image(LocCB);

            // Lưu danh sách để lọc/sort sau này
            Session["ListChuyenBay"] = LocCB;
            Session["ListOld"] = LocCB;

            return View("DatVe", LocCB.listCB);
        }
        public ActionResult TimChuyenVe()
        {
            string diemdi = (string)Session["DiemDen"];  // chiều về đi từ điểm đến chiều đi
            string diemden = (string)Session["DiemDi"];
            DateTime ngaydi = (DateTime)Session["NgayVe"];
            Session["NgayDi"] = ngaydi;
            Session["Chieu"] = "Chọn chuyến cho chiều về";
            SANBAY SBDI = db.SANBAYs.FirstOrDefault(x => x.THANHPHO == diemdi);
            SANBAY SBDen = db.SANBAYs.FirstOrDefault(x => x.THANHPHO == diemden);
            ListChuyenBayModel LocCB = new ListChuyenBayModel();
            ListChuyenBayModel chuyenBayList = (ListChuyenBayModel)Session["ListFull"];
            LocCB.listCB = chuyenBayList.listCB
                           .Where(x => x.GioCatCanh.Date == ngaydi.Date)
                           .ToList();

            // Lọc theo điểm đi và điểm đến
            if (SBDI != null) LocCB.listCB = LocCB.listCB.Where(x => x.DiemDi == SBDI.THANHPHO).ToList();
            if (SBDen != null) LocCB.listCB = LocCB.listCB.Where(x => x.DiemDen == SBDen.THANHPHO).ToList();

            // Cập nhật lại thông tin
            Session["DiemDi"] = diemdi;
            Session["DiemDen"] = diemden;
            Session["NgayDi"] = ngaydi;
            // Gán hình ảnh hãng bay
            Image(LocCB);

            // Lưu danh sách để lọc/sort sau này
            Session["ListChuyenBay"] = LocCB;
            Session["ListOld"] = LocCB;

            return View("DatVe", LocCB.listCB);
        }
        public void Image(ListChuyenBayModel chuyenBayList)
        {
            // === LẤY ẢNH THEO HÃNG (CHỈ ẢNH ĐẦU TIÊN) ===
            var airlineImages = new Dictionary<string, string>();
            string virtualPath = "~/Content/Images/Airline";
            string dirPath = Server.MapPath(virtualPath);
            if (Directory.Exists(dirPath))
            {
                foreach (var cb in chuyenBayList.listCB)
                {
                    if (!airlineImages.ContainsKey(cb.Hang))
                    {
                        string searchPattern = $"{cb.Hang.Trim()}.*";
                        string[] files = Directory.GetFiles(dirPath, searchPattern);
                        if (files.Length > 0)
                        {
                            airlineImages[cb.Hang] = Url.Content(virtualPath + "/" + Path.GetFileName(files[0]));
                        }
                    }
                }
            }
            Session["AirlineImages"] = airlineImages;
        }
        //Sort chuyến bay
        public ActionResult Sort(string sort)
        {
            ListChuyenBayModel list = (ListChuyenBayModel)Session["ListChuyenBay"];
            if (sort == "min")
            {
                ViewBag.Sort = "min";
                return View("DatVe", list.SortMin());
            }
            if (sort == "max")
            {
                ViewBag.Sort = "max";
                return View("DatVe", list.SortMax());
            }
            if (sort == "early")
            {
                ViewBag.Sort = "early";
                return View("DatVe", list.SortEarly());
            }
            if (sort == "timespan")
            {
                ViewBag.Sort = "timespan";
                return View("DatVe", list.SortTimeSpan());
            }

            return View("DatVe", list);
        }
        //Lọc chuyến Bay theo
        [HttpPost]
        public ActionResult LocChuyen(FormCollection form)
        {
            // LẤY DANH SÁCH ĐÃ TÌM TRƯỚC ĐÓ
            var wrapper = Session["ListOld"] as ListChuyenBayModel;
            if (wrapper == null || wrapper.listCB == null || wrapper.listCB.Count == 0)
                return View("DatVe");

            List<ChuyenBayModel> list = new List<ChuyenBayModel>(wrapper.listCB);

            // === LỌC THEO GIÁ ===
            var giaChecks = form.GetValues("gia") ?? new string[0];
            if (giaChecks.Length > 0)
            {
                list = list.Where(x =>
                {
                    if (giaChecks.Contains("duoi2") && x.Gia < 2000000) return true;
                    if (giaChecks.Contains("2den5") && x.Gia >= 2000000 && x.Gia <= 5000000) return true;
                    if (giaChecks.Contains("tren5") && x.Gia > 5000000) return true;
                    return false;
                }).ToList();
            }

            // === LỌC THEO HÃNG ===
            var hangChecks = form.GetValues("hang") ?? new string[0];
            if (hangChecks.Length > 0)
            {
                list = list.Where(x => hangChecks.Contains(x.Hang)).ToList();
            }

            // === LỌC THEO GIỜ KHỞI HÀNH ===
            var gioChecks = form.GetValues("gio") ?? new string[0];
            if (gioChecks.Length > 0)
            {
                list = list.Where(x =>
                {
                    int hour = x.GioCatCanh.Hour;
                    if (gioChecks.Contains("sang") && hour >= 6 && hour < 12) return true;
                    if (gioChecks.Contains("chieu") && hour >= 12 && hour < 18) return true;
                    if (gioChecks.Contains("toi") && hour >= 18) return true;
                    return false;
                }).ToList();
            }

            // === LỌC THEO HẠNG VÉ ===
            var hanggheChecks = form.GetValues("hangghe") ?? new string[0];
            if (hanggheChecks.Length > 0)
            {
                list = list.Where(x => hanggheChecks.Contains(x.HangGhe)).ToList();
            }
            // === LƯU TRẠNG THÁI BỘ LỌC VÀO SESSION ===
            Session["Filter_Gia"] = giaChecks;
            Session["Filter_Hang"] = hangChecks;
            Session["Filter_Gio"] = gioChecks;
            Session["Filter_HangGhe"] = hanggheChecks;

            // === LƯU LẠI ĐỂ SORT SAU NÀY ===
            Session["ListChuyenBay"] = new ListChuyenBayModel { listCB = list };

            return View("DatVe", list);

        }
        //Trang Chon Chỗ
        public ActionResult ChonCho(string MaCB)
        {
            ListChuyenBayModel list = (ListChuyenBayModel)Session["ListChuyenBay"];
            ChuyenBayModel chuyenBay = list.listCB.FirstOrDefault(x => x.MaCB.Trim() == MaCB.Trim());
            Session["DiemDi"] = chuyenBay.DiemDi;
            Session["DiemDen"] = chuyenBay.DiemDen;
            // 1. Lấy danh sách ghế đã mua (đã thanh toán)
            var gheDaMua = (from v in db.VEMAYBAYs
                            join g in db.GHEs on v.MAGHE equals g.MAGHE
                            where v.MACB == MaCB
                            select g.TENGHE).ToList();

            // 2. Lấy danh sách ghế đang giữ trong giỏ hàng
            var gheDangGiu = db.GIOHANG_HANHKHACH
                               .Where(hk => hk.MACB == MaCB)
                               .Select(hk => hk.SOGHE)
                               .ToList();

            // 3. Gộp và CHUẨN HÓA dữ liệu (Trim khoảng trắng)
            var danhSachGheBan = gheDaMua.Union(gheDangGiu)
                                         .Where(s => !string.IsNullOrEmpty(s))
                                         .Select(s => s.Trim())
                                         .Distinct()
                                         .ToList();
            var model = new ChonChoModel
            {
                MaCB = MaCB,
                Hang = chuyenBay.Hang,
                MaMB = chuyenBay.MaMB,
                DiemDi = chuyenBay.DiemDi,
                DiemDen = chuyenBay.DiemDen,
                GioCatCanh = chuyenBay.GioCatCanh,
                GioHaCanh = chuyenBay.GioCatCanh,
                SoHanhKhach = (int)Session["passenger"],

                // Gán danh sách đã sửa vào đây
                GheDaDat = danhSachGheBan,

                CauHinhGhe = db.CAUHINH_GHE
                    .Where(cg => cg.MAMB == chuyenBay.MaMB)
                    .OrderBy(cg => cg.HANGGHE == "Thương Gia" ? 0 : 1)
                    .ThenBy(cg => cg.HANGGHE)
                    .ToList(),
                GiaGhe = db.HANGGHE_GIA
                    .Where(hg => hg.MACB == MaCB)
                    .ToDictionary(hg => hg.HANGGHE, hg => hg.GIA_COSO ?? 0)
            };
            return View(model);
        }
        // lưu thông tin vào giỏ hàng tạm
        public string NewIdGioHang()
        {
            const string prefix = "GH";

            // **SỬA LỖI Ở ĐÂY:** Áp dụng logic sắp xếp an toàn
            var last = db.GIOHANGs
                .Where(g => g.MAGH.StartsWith(prefix))
                .OrderByDescending(g => g.MAGH.Length) // Sắp xếp theo độ dài
                .ThenByDescending(g => g.MAGH)         // Sau đó sắp xếp theo chuỗi
                .FirstOrDefault();                     // Lấy ID lớn nhất

            int nextNumber = 1;

            if (last != null)
            {
                string numPart = last.MAGH.Substring(prefix.Length);
                if (int.TryParse(numPart, out int num))
                {
                    nextNumber = num + 1;
                }
            }

            // **QUAN TRỌNG: Định dạng thành 3 chữ số (D3)**
            return prefix + nextNumber.ToString("D3");
        }
        [HttpPost]
        public ActionResult LuuVaoGioHangChiTiet(ChiTietGioHang model)
        {
            var kh = Session["UserName"] as KHACHHANG;
            if (kh == null) return RedirectToAction("DangNhap");

            // 1. Tìm hoặc Tạo giỏ hàng
            var gioHang = db.GIOHANGs.FirstOrDefault(g => g.MAKH == kh.MAKH && g.TRANGTHAI == "Đang Chọn");

            if (gioHang == null)
            {
                gioHang = new GIOHANG
                {
                    MAGH = NewIdGioHang(),
                    MAKH = kh.MAKH,
                    NGAYTAO = DateTime.Now,
                    TRANGTHAI = "Đang Chọn"
                };
                db.GIOHANGs.Add(gioHang);
                db.SaveChanges();
            }

            decimal totalCalculatedPrice = 0;
            if (model.Passengers != null)
            {
                foreach (var p in model.Passengers)
                {
                    var hangGhe = db.HANGGHE_GIA.FirstOrDefault(x => x.MACB == model.MaCB && x.HANGGHE == p.SeatClass);
                    decimal giaCoSo = hangGhe != null && hangGhe.GIA_COSO.HasValue ? hangGhe.GIA_COSO.Value : 0;
                    totalCalculatedPrice += giaCoSo + (p.CarryOnFee ?? 0) + (p.CheckedFee ?? 0);
                }
            }

            // 2. Lưu chi tiết chuyến bay
            var chiTiet = db.GIOHANG_CHITIET.FirstOrDefault(ct => ct.MAGH == gioHang.MAGH && ct.MACB == model.MaCB);
            if (chiTiet == null)
            {
                chiTiet = new GIOHANG_CHITIET
                {
                    MAGH = gioHang.MAGH,
                    MACB = model.MaCB,
                    SOLUONG = model.Passengers.Count,
                    GIATIEN = totalCalculatedPrice,
                    THOIGIANGIU = DateTime.Now.AddMinutes(15)
                };
                db.GIOHANG_CHITIET.Add(chiTiet);
            }
            else
            {
                chiTiet.SOLUONG += model.Passengers.Count;
                chiTiet.GIATIEN += totalCalculatedPrice;
                db.Entry(chiTiet).State = EntityState.Modified;
            }
            
            int offsetHanhKhach = 0;
            // 3. Lưu hành khách (QUAN TRỌNG: Lưu SOGHE)
            foreach (var item in model.Passengers) 
            {
                // Kiểm tra xem ghế này đã bị ai mua hoặc giữ chưa
                bool daBiChiems = db.VEMAYBAYs.Any(v => v.MACB == model.MaCB && v.GHE.TENGHE == item.Seat)
                                  || db.GIOHANG_HANHKHACH.Any(hk => hk.MACB == model.MaCB && hk.SOGHE == item.Seat);

                if (daBiChiems)
                {
                    // Nếu bị chiếm, báo lỗi và đẩy người dùng quay lại chọn lại
                    TempData["Error"] = $"Ghế {item.Seat} vừa được người khác chọn. Vui lòng chọn ghế khác.";

                    return RedirectToAction("ChonCho", new { MaCB = model.MaCB });
                }
                string maHK = NewIdHanhKhachGH(offsetHanhKhach);
                offsetHanhKhach++;

                var ghk = new GIOHANG_HANHKHACH
                {
                    MAHK = maHK,
                    MAGH = gioHang.MAGH,
                    MACB = model.MaCB,
                    TENHANHKHACH = item.Name,
                    NGAYSINH = DateTime.Parse(item.Dob),
                    GIOITINH = item.Gender,
                    EMAIL = item.Email ?? "",
                    HANGLY_XACHTAY = item.CarryOnFee,
                    HANHLYKYGUI = item.CheckedFee,
                    SOGHE = item.Seat,
                    HANGGHE = item.SeatClass,
                    SDT = item.Phone ?? ""
                };

                db.GIOHANG_HANHKHACH.Add(ghk);
            }

            try
            {
                db.SaveChanges();
            }
            catch (System.Data.Entity.Infrastructure.DbUpdateException ex)
            {
                var sqlEx = ex.GetBaseException() as System.Data.SqlClient.SqlException;
                if (sqlEx != null)
                {
                    string msg = sqlEx.Message;
                    if (msg.Contains("ít nhất 2 tuổi"))
                        msg = "Hành khách phải ít nhất 2 tuổi!";
                    else
                        msg = msg.Split('\n')[0].Trim();

                    ViewBag.Error = msg;
                    ModelState.AddModelError("", msg);
                }
                else
                {
                    ViewBag.Error = "Đã xảy ra lỗi khi lưu thông tin hành khách.";
                    ModelState.AddModelError("", "Đã xảy ra lỗi khi lưu thông tin hành khách.");
                }

                // Restore ChonChoModel to return View without losing data
                ListChuyenBayModel list = (ListChuyenBayModel)Session["ListChuyenBay"];
                ChuyenBayModel chuyenBay = list.listCB.FirstOrDefault(x => x.MaCB.Trim() == model.MaCB.Trim());
                var gheDaMua = (from v in db.VEMAYBAYs
                                join g in db.GHEs on v.MAGHE equals g.MAGHE
                                where v.MACB == model.MaCB
                                select g.TENGHE).ToList();
                var gheDangGiu = db.GIOHANG_HANHKHACH.Where(hk => hk.MACB == model.MaCB).Select(hk => hk.SOGHE).ToList();
                var danhSachGheBan = gheDaMua.Union(gheDangGiu).Where(s => !string.IsNullOrEmpty(s)).Select(s => s.Trim()).Distinct().ToList();

                var chonChoModel = new ChonChoModel
                {
                    MaCB = model.MaCB,
                    Hang = chuyenBay.Hang,
                    MaMB = chuyenBay.MaMB,
                    DiemDi = chuyenBay.DiemDi,
                    DiemDen = chuyenBay.DiemDen,
                    GioCatCanh = chuyenBay.GioCatCanh,
                    GioHaCanh = chuyenBay.GioCatCanh,
                    SoHanhKhach = (int)Session["passenger"],
                    GheDaDat = danhSachGheBan,
                    CauHinhGhe = db.CAUHINH_GHE.Where(cg => cg.MAMB == chuyenBay.MaMB).OrderBy(cg => cg.HANGGHE == "Thương Gia" ? 0 : 1).ThenBy(cg => cg.HANGGHE).ToList(),
                    GiaGhe = db.HANGGHE_GIA.Where(hg => hg.MACB == model.MaCB).ToDictionary(hg => hg.HANGGHE, hg => hg.GIA_COSO ?? 0)
                };

                ViewBag.SubmittedPassengers = model.Passengers;
                return View("ChonCho", chonChoModel);
            }

            // 4. Điều hướng
            string tripType = Session["trip-type"] as string;
            string currentChieu = Session["Chieu"] as string;

            if (tripType == "Khứ hồi" && currentChieu == "Chọn chuyến cho chiều đi")
            {
                Session["DaChonChieuDi"] = true;
                return RedirectToAction("TimChuyenVe");
            }
            else
            {
                return RedirectToAction("ThanhToan", new { ids = gioHang.MAGH.Trim(), cb = model.MaCB });
            }
        }
        public string NewIdHanhKhachGH(int offset = 0)
        {
            var allCodes = db.GIOHANG_HANHKHACH
                     .Where(x => x.MAHK.StartsWith("HK"))
                     .Select(x => x.MAHK)
                     .ToList();

            int maxNum = 0;

            foreach (var code in allCodes)
            {
                // Thử lấy phần số sau "HK", bỏ hết ký tự không phải số
                string numStr = code.Substring(2).TrimStart('0'); // bỏ HK và các số 0 đầu
                if (string.IsNullOrEmpty(numStr)) continue;

                // Lấy chuỗi số đầu tiên trong mã (ví dụ HK01GH01 → 1, HKGH011 → 11)
                string digits = new string(numStr.TakeWhile(char.IsDigit).ToArray());
                if (int.TryParse(digits, out int num))
                {
                    if (num > maxNum) maxNum = num;
                }
            }

            // Tạo mã mới = HK + số lớn nhất + 1 + offset, định dạng 4 chữ số
            return "HK" + (maxNum + 1 + offset).ToString("D4");
        }
        // Trang Thanh Toán
        [HttpGet]
        public ActionResult ThanhToan(string ids, string cb)
        {
            var khachHang = Session["UserName"] as KHACHHANG;
            if (khachHang == null)
            {
                return RedirectToAction("DangNhap", "User");
            }

            Session["Ve"] = null;
            TempData["PaymentSuccess"] = null;
            if (string.IsNullOrEmpty(ids))
            {
                // không có mã giỏ hàng → quay lại trang vé
                return RedirectToAction("VeCuaToi");
            }

            string[] idList = ids.Split(',');
            string[] idcb = cb.Split(',');
            string[] maChuyenBayCanTimArray = idcb ?? Array.Empty<string>();
            List<CartItemDetailViewModel> viewModelList = new List<CartItemDetailViewModel>();

            // 1. Truy vấn thông tin cơ bản của giỏ hàng chi tiết (chuyến bay, lộ trình, sân bay)
            var finalCartItems = (from ct in db.GIOHANG_CHITIET
                                  join lt in db.LOTRINHs on ct.MACB equals lt.MACB
                                  join sbdi in db.SANBAYs on lt.SBDI equals sbdi.MASB
                                  join sbden in db.SANBAYs on lt.SBDEN equals sbden.MASB
                                  where idList.Contains(ct.MAGH) && maChuyenBayCanTimArray.Contains(ct.MACB)
                                  select new
                                  {
                                      ChiTiet = ct,
                                      Lotrinh = lt,
                                      SanBayDi = sbdi,
                                      SanBayDen = sbden
                                  }).ToList();

            foreach (var item in finalCartItems)
            {
                // Tính giá trung bình cho 1 hành khách. Giá này được dùng để ước lượng hạng ghế đã chọn.
                decimal unitPrice = item.ChiTiet.SOLUONG > 0
                    ? item.ChiTiet.GIATIEN.Value / item.ChiTiet.SOLUONG.Value
                    : 0;

                // Lấy danh sách hành khách thuộc giỏ hàng và chuyến bay này
                var passengers = db.GIOHANG_HANHKHACH
                    .Where(h => idList.Contains(h.MAGH) && h.MACB == item.ChiTiet.MACB)
                    .ToList();

                foreach (var p in passengers)
                {
                    // Tìm giá cơ sở chính xác dựa trên HANGGHE lưu trong hành khách
                    var hangGheGia = db.HANGGHE_GIA
                        .FirstOrDefault(h => h.MACB == item.ChiTiet.MACB && h.HANGGHE == p.HANGGHE);

                    // Thêm vào danh sách ViewModel
                    viewModelList.Add(new CartItemDetailViewModel
                    {
                        MaHanhKhachGH = p.MAHK,
                        MaGioHang = idList[0],
                        TenHanhKhach = p.TENHANHKHACH,
                        GioiTinhHK = p.GIOITINH,
                        MaChuyenBay = item.ChiTiet.MACB,
                        SanBayDiTen = item.SanBayDi.TENSB,
                        SanBayDenTen = item.SanBayDen.TENSB,
                        GioCatCanh = item.Lotrinh.GIOCATCANH,
                        HangGhe = p.HANGGHE ?? hangGheGia?.HANGGHE ?? "Phổ thông",
                        GiaVeCoSo = (int)(hangGheGia?.GIA_COSO ?? 0) + (p.HANGLY_XACHTAY ?? 0) + (p.HANHLYKYGUI ?? 0)
                    });
                }
            }


            return View(viewModelList);
        }
        // Tạo mã ghế mới
        private string TaoMaGheMoi()
        {
            // Cách an toàn nhất: Tìm mã lớn nhất có dạng GHxxx rồi +1
            // Tránh lỗi khi dữ liệu trống hoặc mã không chuẩn
            var lastGhe = db.GHEs
                .Where(g => g.MAGHE != null && g.MAGHE.StartsWith("GH") && g.MAGHE.Length >= 5)
                .OrderByDescending(g => g.MAGHE)
                .Select(g => g.MAGHE)
                .FirstOrDefault();

            if (string.IsNullOrEmpty(lastGhe))
                return "GH001";

            // Lấy phần số sau "GH"
            string numberPart = lastGhe.Substring(2); // vd: "001", "123", "999"

            if (int.TryParse(numberPart, out int lastNumber))
            {
                int newNumber = lastNumber + 1;
                return "GH" + newNumber.ToString("D3"); // D3 → luôn 3 chữ số: 001, 010, 100, 999...
            }

            // Nếu parse lỗi (dữ liệu bị hỏng) → fallback an toàn
            return "GH" + DateTime.Now.Ticks.ToString().Substring(10); // mã gần như không trùng
        }
        // Tạo mã phiếu mới
        // Thêm vào UserController.cs
        public string NewIdPhieuDatVe()
        {
            const string prefix = "PDV";
            // Tìm mã phiếu lớn nhất hiện có
            var last = db.PHIEUDATVEs
                .Where(p => p.MAPHIEU.StartsWith(prefix))
                .OrderByDescending(p => p.MAPHIEU.Length)
                .ThenByDescending(p => p.MAPHIEU)
                .FirstOrDefault();

            int nextNumber = 1;
            if (last != null)
            {
                string numPart = last.MAPHIEU.Substring(prefix.Length);
                if (int.TryParse(numPart, out int num))
                {
                    nextNumber = num + 1;
                }
            }
            // Trả về định dạng PD001, PD002...
            return prefix + nextNumber.ToString("D3");
        }
        //tạo vé
        [HttpPost]
        public ActionResult TaoVe(string maGH, string maCB)
        {
            // Lấy giỏ hàng
            GIOHANG gioHang = db.GIOHANGs.FirstOrDefault(g => g.MAGH == maGH);
            if (gioHang == null) return RedirectToAction("TrangChu");

            var gioHangChiTietList = db.GIOHANG_CHITIET.Where(ct => ct.MAGH == maGH && ct.MACB == maCB).ToList();
            var hanhKhachList = db.GIOHANG_HANHKHACH.Where(hk => hk.MAGH == maGH && hk.MACB == maCB).ToList();
            List<VEMAYBAY> listve = new List<VEMAYBAY>();

            // Sử dụng Transaction để đảm bảo toàn vẹn dữ liệu
            using (var transaction = db.Database.BeginTransaction())
            {
                // 1. TẠO PHIẾU ĐẶT VÉ
                string maPhieu = NewIdPhieuDatVe();
                PHIEUDATVE phieu = new PHIEUDATVE
                {
                    MAPHIEU = maPhieu,
                    NGLAP = DateTime.Now,
                    MAKH = gioHang.MAKH,
                    MANV = null,
                    TRANGTHAI = "Đã thanh toán",
                    MAGH = maGH
                };
                db.PHIEUDATVEs.Add(phieu);
                db.SaveChanges();

                // 2. TẠO VÉ VÀ CHI TIẾT
                foreach (var chiTiet in gioHangChiTietList)
                {
                    var chuyenBay = db.CHUYENBAYs.FirstOrDefault(cb => cb.MACB == chiTiet.MACB);
                    var hanhKhachsChoChuyenBay = hanhKhachList.Where(hk => hk.MACB == chiTiet.MACB).ToList();

                    foreach (var hk in hanhKhachsChoChuyenBay)
                    {
                        // Xử lý Ghế
                        var gheTonTai = db.GHEs.FirstOrDefault(g => g.MAMB == chuyenBay.MAMB && g.TENGHE == hk.SOGHE);
                        string maGheDB;

                        if (gheTonTai != null)
                        {
                            maGheDB = gheTonTai.MAGHE;
                        }
                        else
                        {
                            string newMaGhe = TaoMaGheMoi();
                            var newGhe = new GHE
                            {
                                MAGHE = newMaGhe,
                                MAMB = chuyenBay.MAMB,
                                TENGHE = hk.SOGHE,
                                HANGGHE = hk.HANGGHE
                            };
                            db.GHEs.Add(newGhe);
                            db.SaveChanges();
                            maGheDB = newMaGhe;
                        }

                        // Tạo Vé Máy Bay
                        var giaGheObj = db.HANGGHE_GIA.FirstOrDefault(h => h.MACB == chiTiet.MACB && h.HANGGHE == hk.HANGGHE);
                        decimal giaVe = giaGheObj?.GIA_COSO ?? 0;

                        VEMAYBAY ve = new VEMAYBAY
                        {
                            MAVE = TaoMaVeNgauNhien(),
                            MACB = chiTiet.MACB,
                            MAGHE = maGheDB,
                            MAHG = giaGheObj?.MAHG,
                            GIAVE = giaVe,
                            MANV = null
                        };
                        db.VEMAYBAYs.Add(ve);
                        db.SaveChanges(); // Lưu vé ngay để lấy MAVE cho bảng CHITIETVE

                        listve.Add(ve);

                        // Tạo Chi Tiết Vé
                        CHITIETVE ctv = new CHITIETVE
                        {
                            MAVE = ve.MAVE,
                            MAPHIEU = maPhieu,
                            NGAYDAT = DateTime.Now,
                            GIATIEN = giaVe
                        };
                        db.CHITIETVEs.Add(ctv);
                    }
                }

                // 3. CẬP NHẬT GIỎ HÀNG
                gioHang.TRANGTHAI = "Đã Thanh Toán";
                db.Entry(gioHang).State = EntityState.Modified;

                // Lưu tất cả thay đổi còn lại (ChiTietVe, GioHang)
                db.SaveChanges();

                // Xác nhận giao dịch thành công
                transaction.Commit();

                Session["Ve"] = listve;
                TempData["PaymentSuccess"] = true;
                return RedirectToAction("ThanhToan", new { id = maGH });

            }
        }

        // tạo mã vé
        public string TaoMaVeNgauNhien(int doDai = 7)
        {
            const string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
            var random = new Random();
            string maVe;

            do
            {
                maVe = "TKT" + new string(Enumerable.Repeat(chars, doDai)
                    .Select(s => s[random.Next(s.Length)]).ToArray());
            }
            while (db.VEMAYBAYs.Any(v => v.MAVE == maVe)); // Đảm bảo không trùng

            return maVe;
        }
        // Vé của tôi 
        public ActionResult VeCuaToi()
        {
            var khachHang = Session["UserName"] as KHACHHANG;
            if (khachHang == null)
                return RedirectToAction("DangNhap");
            // Tìm các chi tiết giỏ hàng của khách này mà thời gian giữ < hiện tại và chưa thanh toán
            var expiredItems = db.GIOHANG_CHITIET
                .Where(ct => ct.GIOHANG.MAKH == khachHang.MAKH
                             && ct.GIOHANG.TRANGTHAI != "Đã Thanh Toán" // Chỉ check đơn chưa thanh toán
                             && (ct.THOIGIANGIU < DateTime.Now || ct.THOIGIANGIU == null))
                .ToList();

            if (expiredItems.Any())
            {
                foreach (var item in expiredItems)
                {
                    // 1. Xóa hành khách liên quan
                    var hkList = db.GIOHANG_HANHKHACH
                        .Where(h => h.MAGH == item.MAGH && h.MACB == item.MACB)
                        .ToList();
                    db.GIOHANG_HANHKHACH.RemoveRange(hkList);

                    // 2. Xóa chi tiết chuyến bay này
                    db.GIOHANG_CHITIET.Remove(item);
                }
                db.SaveChanges();
                // Nếu giỏ hàng rỗng sau khi xóa chi tiết, có thể xóa luôn giỏ hàng

                var gioHangRong = db.GIOHANGs
                    .Where(g => g.MAKH == khachHang.MAKH && !db.GIOHANG_CHITIET.Any(ct => ct.MAGH == g.MAGH))
                    .ToList();
                db.GIOHANGs.RemoveRange(gioHangRong);
                db.SaveChanges();

            }
            var model = new MyTicketsViewModel
            {
                UnpaidOrders = new List<OrderTicketViewModel>(),
                PaidOrders = new List<OrderTicketViewModel>()
            };

            // Lấy tất cả giỏ hàng của khách
            var gioHangs = db.GIOHANGs
                .Where(g => g.MAKH == khachHang.MAKH)
                .OrderByDescending(g => g.NGAYTAO)
                .ToList();

            foreach (var gh in gioHangs)
            {
                // === BƯỚC 1: Lấy TẤT CẢ chuyến bay (chi tiết) từ giỏ hàng hiện tại ===
                var allCt = db.GIOHANG_CHITIET.Where(x => x.MAGH == gh.MAGH).ToList();
                if (!allCt.Any()) continue;

                // === BƯỚC 2: Duyệt qua từng chuyến bay (ct) riêng biệt ===
                foreach (var ct in allCt)
                {
                    var macb = ct.MACB;
                    var loTrinh = db.LOTRINHs.FirstOrDefault(lt => lt.MACB == macb);
                    if (loTrinh == null) continue;

                    var sbDi = db.SANBAYs.FirstOrDefault(s => s.MASB == loTrinh.SBDI);
                    var sbDen = db.SANBAYs.FirstOrDefault(s => s.MASB == loTrinh.SBDEN);

                    var timeSpan = loTrinh.GIOHACANH - loTrinh.GIOCATCANH;
                    var thoiGianBay = timeSpan.Hours > 0
                        ? $"{timeSpan.Hours}h {timeSpan.Minutes:D2}m"
                        : $"{timeSpan.Minutes}m";

                    // TẠO MỘT OrderTicketViewModel MỚI CHO MỖI CHUYẾN BAY (ct)
                    var order = new OrderTicketViewModel
                    {
                        MaGioHang = gh.MAGH,
                        TrangThai = gh.TRANGTHAI ?? "Đang chọn",
                        NgayDat = gh.NGAYTAO ?? DateTime.Now,
                        TongTienGioHang = ct.GIATIEN ?? 0m, // Giá tiền ban đầu của chuyến bay này

                        MaChuyenBay = macb,
                        SanBayDiTen = sbDi?.TENSB ?? "N/A",
                        SanBayDenTen = sbDen?.TENSB ?? "N/A",
                        SanBayDiMa = sbDi?.MASB,
                        SanBayDenMa = sbDen?.MASB,

                        GioCatCanh = loTrinh.GIOCATCANH,
                        GioHaCanh = loTrinh.GIOHACANH,
                        NgayBay = loTrinh.GIOCATCANH.Date,
                        ThoiGianBay = thoiGianBay,

                        ThoiGianGiuCho = ct.THOIGIANGIU ?? DateTime.Now.AddMinutes(15),

                        Tickets = new List<TicketDetailViewModel>()
                    };

                    // Lấy danh sách hành khách chỉ cho chuyến bay (ct.MACB) này
                    var hanhKhachList = db.GIOHANG_HANHKHACH
                        .Where(hk => hk.MAGH == gh.MAGH && hk.MACB == macb)
                        .ToList();

                    // ==================== CHƯA THANH TOÁN ====================
                    if (!gh.TRANGTHAI.Contains("Thanh Toán"))
                    {
                        decimal totalOrderPrice = 0m;

                        foreach (var hk in hanhKhachList)
                        {
                            // Lấy giá cơ sở theo MACB hiện tại
                            var giaCoSo = db.HANGGHE_GIA
                                .FirstOrDefault(hg => hg.MACB == macb && hg.HANGGHE == hk.HANGGHE)?.GIA_COSO ?? 0m;

                            // Tính tổng tiền vé
                            decimal price = giaCoSo + (hk.HANGLY_XACHTAY ?? 0m) + (hk.HANHLYKYGUI ?? 0m);
                            totalOrderPrice += price;

                            order.Tickets.Add(new TicketDetailViewModel
                            {
                                ID = hk.MAHK,
                                TenHanhKhach = hk.TENHANHKHACH ?? "Khách hàng",
                                SoGhe = hk.SOGHE,
                                HangGhe = hk.HANGGHE,
                                GioiTinh = hk.GIOITINH,
                                GioiTinhHienThi = hk.GIOITINH,
                                NgaySinh = hk.NGAYSINH,
                                TongTienVe = price,
                                IsPaid = false
                            });
                        }

                        // Cập nhật tổng tiền (chỉ tính tiền cho chuyến bay này)
                        order.TongTienGioHang = totalOrderPrice;

                        // THÊM ĐƠN HÀNG/CHUYẾN BAY MỚI VÀO DANH SÁCH CHƯA THANH TOÁN
                        model.UnpaidOrders.Add(order);
                    }
                    // ==================== ĐÃ THANH TOÁN ====================
                    else
                    {
                        if (!hanhKhachList.Any())
                        {
                            model.PaidOrders.Add(order);
                            continue;
                        }

                        // Khởi tạo tổng tiền cho đơn hàng đã thanh toán (dù không dùng)
                        decimal totalOrderPricePaid = 0m;

                        foreach (var hk in hanhKhachList)
                        {
                            // Tìm vé theo số ghế (sử dụng macb hiện tại)
                            var maMB = db.CHUYENBAYs.FirstOrDefault(cb => cb.MACB == macb)?.MAMB;
                            var ghe = maMB != null ? db.GHEs.FirstOrDefault(g => g.TENGHE == hk.SOGHE && g.MAMB == maMB) : null;
                            var ve = ghe != null ? db.VEMAYBAYs.FirstOrDefault(v => v.MAGHE == ghe.MAGHE && v.MACB == macb) : null;

                            var tenHangGhe = hk.HANGGHE;
                            decimal giaVe = 0m;

                            if (ve != null)
                            {
                                giaVe = ve.GIAVE ?? 0m;
                                var hg = db.HANGGHE_GIA.FirstOrDefault(h => h.MAHG == ve.MAHG);
                                if (hg != null) tenHangGhe = hg.HANGGHE;
                            }
                            else
                            {
                                // Nếu không có vé thật → chia đều giá giỏ hàng (chỉ chia giá của chuyến bay này: ct.GIATIEN)
                                giaVe = hanhKhachList.Count > 0 ? (ct.GIATIEN ?? 0m) / hanhKhachList.Count : 0m;
                            }

                            totalOrderPricePaid += giaVe; // Cộng dồn giá vé đã thanh toán

                            order.Tickets.Add(new TicketDetailViewModel
                            {
                                MaVe = ve?.MAVE ?? "TKT" + new Random().Next(100000, 999999).ToString(),
                                TenHanhKhach = hk.TENHANHKHACH ?? "Khách hàng",
                                GioiTinh = hk.GIOITINH,
                                NgaySinh = hk.NGAYSINH,
                                SoGhe = hk.SOGHE ?? "N/A",
                                HangGhe = tenHangGhe,
                                TongTienVe = giaVe,
                                IsPaid = true,
                                SDT = hk.SDT,
                                Email = hk.EMAIL
                            });
                        }

                        // Cập nhật tổng tiền cho đơn hàng đã thanh toán (nên dùng tổng tiền tính lại)
                        order.TongTienGioHang = totalOrderPricePaid;

                        // THÊM ĐƠN HÀNG/CHUYẾN BAY MỚI VÀO DANH SÁCH ĐÃ THANH TOÁN
                        model.PaidOrders.Add(order);
                    }
                }
            }

            return View(model);
        }
        // Hủy vé
        public ActionResult HuyVe(string maGH, string MaCB)
        {

            var gioHang = db.GIOHANGs.FirstOrDefault(g => g.MAGH == maGH);
            if (gioHang == null)
            {
                return RedirectToAction("VeCuaToi");
            }

            if (gioHang.TRANGTHAI.Contains("Thanh Toán"))
            {
                // Nếu là vé đã thanh toán, phải xóa các bảng liên quan đến vé thật
                var phieuDatVe = db.PHIEUDATVEs.FirstOrDefault(p => p.MAGH == maGH);
                if (phieuDatVe != null)
                {
                    var chiTietVes = db.CHITIETVEs.Where(ct => ct.MAPHIEU == phieuDatVe.MAPHIEU && ct.VEMAYBAY.MACB == MaCB).ToList();
                    foreach (var ct in chiTietVes)
                    {
                        var mave = ct.MAVE;
                        db.CHITIETVEs.Remove(ct);
                        var ve = db.VEMAYBAYs.FirstOrDefault(v => v.MAVE == mave);
                        if (ve != null) db.VEMAYBAYs.Remove(ve);
                    }
                    if (!db.CHITIETVEs.Any(ct => ct.MAPHIEU == phieuDatVe.MAPHIEU && ct.VEMAYBAY.MACB != MaCB))
                    {
                        db.PHIEUDATVEs.Remove(phieuDatVe);
                    }
                }
            }
            try
            {
                // Xóa check-in (nếu có)
                var checkIns = (from ci in db.CHECKINs
                                join hk in db.GIOHANG_HANHKHACH on ci.MAKH equals hk.GIOHANG.MAKH
                                where hk.MAGH == maGH && ci.MACB == MaCB
                                select ci).Distinct().ToList();
                foreach (var ci in checkIns)
                {
                    db.CHECKINs.Remove(ci);
                }

                // Xóa hành khách
                var hkList = db.GIOHANG_HANHKHACH.Where(h => h.MAGH == maGH && h.MACB == MaCB).ToList();
                db.GIOHANG_HANHKHACH.RemoveRange(hkList);

                // Xóa chi tiết giỏ hàng
                var ctList = db.GIOHANG_CHITIET.Where(c => c.MAGH == maGH && c.MACB == MaCB).ToList();
                db.GIOHANG_CHITIET.RemoveRange(ctList);

                db.SaveChanges();

                TempData["Success"] = "Hủy đơn hàng thành công!";
            }
            catch
            {
                TempData["Error"] = "Có lỗi xảy ra, vui lòng thử lại!";
            }

            return RedirectToAction("VeCuaToi");
        }

        // Check-in cho khách hàng đã đăng nhập
        public ActionResult CheckIn(string filter = "ready")
        {
            var khachHang = Session["UserName"] as KHACHHANG;
            if (khachHang == null)
            {
                ViewBag.ChuaDangNhap = true;
                return View();
            }
            ViewBag.ChuaDangNhap = false;

            // Lấy tất cả vé đã thanh toán của khách hàng
            var veList = (from ve in db.VEMAYBAYs
                          join ct in db.CHITIETVEs on ve.MAVE equals ct.MAVE
                          join pdv in db.PHIEUDATVEs on ct.MAPHIEU equals pdv.MAPHIEU
                          join gh in db.GIOHANGs on pdv.MAGH equals gh.MAGH
                          where gh.MAKH == khachHang.MAKH && pdv.TRANGTHAI.Contains("thanh toán")
                          select new { Ve = ve, GioHang = gh, PhieuDatVe = pdv }).Distinct().ToList();

            var checkInList = new List<CheckInViewModel>();

            foreach (var item in veList)
            {
                var ve = item.Ve;
                var gioHang = item.GioHang;

                // Lấy thông tin chuyến bay
                var chuyenBay = db.CHUYENBAYs.FirstOrDefault(cb => cb.MACB == ve.MACB);
                if (chuyenBay == null) continue;

                var loTrinh = db.LOTRINHs.FirstOrDefault(lt => lt.MACB == ve.MACB);
                if (loTrinh == null) continue;

                var sbDi = db.SANBAYs.FirstOrDefault(s => s.MASB == loTrinh.SBDI);
                var sbDen = db.SANBAYs.FirstOrDefault(s => s.MASB == loTrinh.SBDEN);
                var ghe = db.GHEs.FirstOrDefault(g => g.MAGHE == ve.MAGHE);
                var hangGheGia = db.HANGGHE_GIA.FirstOrDefault(hg => hg.MAHG == ve.MAHG);
                string trangThai = "CHƯA CẤT CÁNH";
                try
                {
                    trangThai = db.Database.SqlQuery<string>(
                        "EXEC sp_KiemTraTrangThaiChuyenBay @MACB",
                        new SqlParameter("@MACB", ve.MACB)
                        ).FirstOrDefault();
                }
                catch
                {
                    var nowTime = DateTime.Now;
                    if (nowTime > loTrinh.GIOHACANH) trangThai = "ĐÃ HẠ CÁNH";
                    else if (nowTime >= loTrinh.GIOCATCANH && nowTime <= loTrinh.GIOHACANH) trangThai = "ĐANG BAY";
                    else trangThai = "CHƯA CẤT CÁNH";
                }

                // KIỂM TRA ĐÚNG VỚI GIÁ TRỊ TRẢ VỀ TỪ PROCEDURE
                if (trangThai == "ĐÃ HẠ CÁNH")
                {
                    ViewBag.Notify = "Bạn không thể check-in vì máy bay đã hạ cánh.";
                }
                else if (trangThai == "ĐANG BAY")
                {
                    ViewBag.Notify = "Bạn không thể check-in vì máy bay đang bay.";
                }
                else if (trangThai == "CHƯA CẤT CÁNH")
                {
                    ViewBag.Notify = "Bạn có thể check-in nếu đã tới giờ.";
                }


                // Lấy thông tin check-in
                var checkIn = db.CHECKINs.FirstOrDefault(ci => ci.MAVE == ve.MAVE);

                // Lấy thông tin hành khách từ GIOHANG_HANHKHACH
                // Lấy TENGHE trước để tránh lỗi LINQ
                string tenghe = ghe?.TENGHE;
                var ghk = db.GIOHANG_HANHKHACH
                    .FirstOrDefault(hk => hk.MAGH == gioHang.MAGH &&
                                         tenghe != null && hk.SOGHE == tenghe);

                // Tính thời gian bay
                var timeSpan = loTrinh.GIOHACANH - loTrinh.GIOCATCANH;
                var thoiGianBay = timeSpan.Hours > 0
                    ? $"{timeSpan.Hours}h {timeSpan.Minutes:D2}m"
                    : $"{timeSpan.Minutes}m";
                
               

                // Kiểm tra có thể check-in (từ 24h trước đến 1h trước giờ bay)
                //var now = DateTime.Now;
                //var thoiGianCheckInBatDau = loTrinh.GIOCATCANH.AddHours(-24);
                //var thoiGianCheckInKetThuc = loTrinh.GIOCATCANH.AddHours(-1);
                //var coTheCheckIn = now >= thoiGianCheckInBatDau && now <= thoiGianCheckInKetThuc && checkIn == null;

                var now = DateTime.Now;
                var thoiGianCheckInBatDau = loTrinh.GIOCATCANH.AddHours(-24);
                var thoiGianCheckInKetThuc = loTrinh.GIOCATCANH.AddHours(-1);
                // Xác định trạng thái đã check-in
                bool daCheckIn = checkIn != null && checkIn.TRANGTHAI != null &&
                                 (checkIn.TRANGTHAI == "Đã check-in" || checkIn.TRANGTHAI.StartsWith("Đã"));
                // Có thể check-in nếu: trong khung giờ VÀ chưa check-in
                var coTheCheckIn = now >= thoiGianCheckInBatDau && now <= thoiGianCheckInKetThuc && !daCheckIn;

                // Tính thời gian còn lại
                string thoiGianConLai = "";
                if (coTheCheckIn)
                {
                    var conLai = thoiGianCheckInKetThuc - now;
                    if (conLai.TotalHours >= 1)
                        thoiGianConLai = $"Còn {(int)conLai.TotalHours}h";
                    else
                        thoiGianConLai = $"Còn {(int)conLai.TotalMinutes}m";
                }
                else if (now < thoiGianCheckInBatDau)
                {
                    var conLai = thoiGianCheckInBatDau - now;
                    thoiGianConLai = $"Còn {(int)conLai.TotalDays} ngày";
                }

                var model = new CheckInViewModel
                {
                    MaVe = ve.MAVE,
                    MaCB = ve.MACB,
                    MaGhe = ve.MAGHE,
                    SoGhe = ghe?.TENGHE ?? "N/A",
                    HangGhe = hangGheGia?.HANGGHE ?? "Phổ thông",

                    SanBayDiMa = sbDi?.MASB,
                    SanBayDiTen = sbDi?.TENSB,
                    SanBayDiThanhPho = sbDi?.THANHPHO,
                    SanBayDenMa = sbDen?.MASB,
                    SanBayDenTen = sbDen?.TENSB,
                    SanBayDenThanhPho = sbDen?.THANHPHO,
                    GioCatCanh = loTrinh.GIOCATCANH,
                    GioHaCanh = loTrinh.GIOHACANH,
                    ThoiGianBay = thoiGianBay,
                    TrangThaiChuyenBay = trangThai,

                    TenHanhKhach = ghk?.TENHANHKHACH ?? khachHang.TENKH,
                    GioiTinh = ghk?.GIOITINH ?? khachHang.GTINH,
                    NgaySinh = ghk?.NGAYSINH ?? khachHang.NGSINH,
                    Email = ghk?.EMAIL ?? khachHang.EMAIL,
                    SDT = khachHang.SDT,
                    QuocGia = khachHang.QUOCGIA,

                    GiaVe = ve.GIAVE,
                    TrangThaiCheckIn = checkIn?.TRANGTHAI ?? "Chưa check-in",
                    ThoiGianCheckIn = checkIn?.THOIGIAN_CHECKIN,
                    DaCheckIn = daCheckIn,

                    CoTheCheckIn = coTheCheckIn,
                    ThoiGianConLai = thoiGianConLai,

                    HangLyXachTay = ghk?.HANGLY_XACHTAY ?? 0,
                    HangLyKyGui = ghk?.HANHLYKYGUI ?? 0
                };

                checkInList.Add(model);
            }

            // Sắp xếp theo giờ bay gần nhất
            checkInList = checkInList.OrderBy(x => x.GioCatCanh).ToList();

            ViewBag.TongChuyenBay = checkInList.Count;
            ViewBag.SanSangCheckIn = checkInList.Count(x => x.CoTheCheckIn);
            ViewBag.DaCheckIn = checkInList.Count(x => x.DaCheckIn);
            // Tính số vé hết hạn (sau thời gian check-in kết thúc và chưa check-in)
            var currentTime = DateTime.Now;
            ViewBag.QuaHan = checkInList.Count(x => {
                var lt = db.LOTRINHs.FirstOrDefault(l => l.MACB == x.MaCB);
                if (lt == null) return false;
                var thoiGianKetThuc = lt.GIOCATCANH.AddHours(-1);
                return currentTime > thoiGianKetThuc && !x.DaCheckIn;
            });
            ViewBag.CurrentFilter = filter;
            if (filter == "ready")
            {
                checkInList = checkInList.Where(x => x.CoTheCheckIn).ToList();
            }
            else if (filter == "checkedin")
            {
                checkInList = checkInList.Where(x => x.DaCheckIn).ToList();
            }
            else if (filter == "overdue")
            {
                // Lọc vé hết hạn: sau thời gian check-in kết thúc và chưa check-in
                checkInList = checkInList.Where(x => {
                    var lt = db.LOTRINHs.FirstOrDefault(l => l.MACB == x.MaCB);
                    if (lt == null) return false;
                    var thoiGianKetThuc = lt.GIOCATCANH.AddHours(-1);
                    return currentTime > thoiGianKetThuc && !x.DaCheckIn;
                }).ToList();
                checkInList = checkInList.Where(x => !x.CoTheCheckIn && !x.DaCheckIn).ToList();
            }
            return View(checkInList);
        }

        // Xác nhận check-in - hiển thị chi tiết vé
        public ActionResult XacNhanCheckIn(string maVe)
        {
            var khachHang = Session["UserName"] as KHACHHANG;
            if (khachHang == null)
                return RedirectToAction("DangNhap");

            if (string.IsNullOrEmpty(maVe))
                return RedirectToAction("CheckIn");

            // Lấy thông tin vé
            var ve = db.VEMAYBAYs.FirstOrDefault(v => v.MAVE == maVe);
            if (ve == null)
                return RedirectToAction("CheckIn");

            // Kiểm tra vé thuộc về khách hàng
            var phieuDatVe = (from ct in db.CHITIETVEs
                              join pdv in db.PHIEUDATVEs on ct.MAPHIEU equals pdv.MAPHIEU
                              join gh in db.GIOHANGs on pdv.MAGH equals gh.MAGH
                              where ct.MAVE == maVe && gh.MAKH == khachHang.MAKH
                              select pdv).FirstOrDefault();

            if (phieuDatVe == null)
                return RedirectToAction("CheckIn");

            // Lấy thông tin chi tiết
            var chuyenBay = db.CHUYENBAYs.FirstOrDefault(cb => cb.MACB == ve.MACB);
            var loTrinh = db.LOTRINHs.FirstOrDefault(lt => lt.MACB == ve.MACB);
            var sbDi = db.SANBAYs.FirstOrDefault(s => s.MASB == loTrinh.SBDI);
            var sbDen = db.SANBAYs.FirstOrDefault(s => s.MASB == loTrinh.SBDEN);
            var ghe = db.GHEs.FirstOrDefault(g => g.MAGHE == ve.MAGHE);
            var hangGheGia = db.HANGGHE_GIA.FirstOrDefault(hg => hg.MAHG == ve.MAHG);
            var checkIn = db.CHECKINs.FirstOrDefault(ci => ci.MAVE == ve.MAVE);

            // Lấy thông tin hành khách
            // Lấy TENGHE trước để tránh lỗi LINQ
            string tenghe = ghe?.TENGHE;
            var ghk = db.GIOHANG_HANHKHACH
                .FirstOrDefault(hk => hk.MAGH == phieuDatVe.MAGH &&
                                     tenghe != null && hk.SOGHE == tenghe);

            // Tính thời gian bay
            var timeSpan = loTrinh.GIOHACANH - loTrinh.GIOCATCANH;
            var thoiGianBay = timeSpan.Hours > 0
                ? $"{timeSpan.Hours}h {timeSpan.Minutes:D2}m"
                : $"{timeSpan.Minutes}m";

            var model = new CheckInViewModel
            {
                MaVe = ve.MAVE,
                MaCB = ve.MACB,
                MaGhe = ve.MAGHE,
                SoGhe = ghe?.TENGHE ?? "N/A",
                HangGhe = hangGheGia?.HANGGHE ?? "Phổ thông",

                SanBayDiMa = sbDi?.MASB,
                SanBayDiTen = sbDi?.TENSB,
                SanBayDiThanhPho = sbDi?.THANHPHO,
                SanBayDenMa = sbDen?.MASB,
                SanBayDenTen = sbDen?.TENSB,
                SanBayDenThanhPho = sbDen?.THANHPHO,
                GioCatCanh = loTrinh.GIOCATCANH,
                GioHaCanh = loTrinh.GIOHACANH,
                ThoiGianBay = thoiGianBay,


                TenHanhKhach = ghk?.TENHANHKHACH ?? khachHang.TENKH,
                GioiTinh = ghk?.GIOITINH ?? khachHang.GTINH,
                NgaySinh = ghk?.NGAYSINH ?? khachHang.NGSINH,
                Email = ghk?.EMAIL ?? khachHang.EMAIL,
                SDT = khachHang.SDT,
                QuocGia = khachHang.QUOCGIA,

                GiaVe = ve.GIAVE,
                TrangThaiCheckIn = checkIn?.TRANGTHAI ?? "Chưa check-in",
                ThoiGianCheckIn = checkIn?.THOIGIAN_CHECKIN,
                DaCheckIn = checkIn != null && checkIn.TRANGTHAI != null && (checkIn.TRANGTHAI == "Đã check-in" || checkIn.TRANGTHAI.StartsWith("Đã")),

                HangLyXachTay = ghk?.HANGLY_XACHTAY ?? 0,
                HangLyKyGui = ghk?.HANHLYKYGUI ?? 0
            };

            return View(model);
        }

        // POST: Thực hiện check-in
        [HttpPost]
        public ActionResult ThucHienCheckIn(string maVe)
        {
            var khachHang = Session["UserName"] as KHACHHANG;
            if (khachHang == null)
                return Json(new { success = false, message = "Vui lòng đăng nhập" });
            if (string.IsNullOrEmpty(maVe))
                return Json(new { success = false, message = "Mã vé không hợp lệ" });
            try
            {
                // Lấy thông tin vé
                var ve = db.VEMAYBAYs.FirstOrDefault(v => v.MAVE == maVe);
                if (ve == null)
                    return Json(new { success = false, message = "Không tìm thấy vé" });
                // Kiểm tra vé thuộc về khách hàng
                var phieuDatVe = (from ct in db.CHITIETVEs
                                  join pdv in db.PHIEUDATVEs on ct.MAPHIEU equals pdv.MAPHIEU
                                  join gh in db.GIOHANGs on pdv.MAGH equals gh.MAGH
                                  where ct.MAVE == maVe && gh.MAKH == khachHang.MAKH
                                  select pdv).FirstOrDefault();
                if (phieuDatVe == null)
                    return Json(new { success = false, message = "Vé không thuộc về bạn" });
                if (phieuDatVe.TRANGTHAI != "Đã thanh toán" && phieuDatVe.TRANGTHAI != "Đã đặt")
                    return Json(new { success = false, message = "Vé không hợp lệ, chưa thanh toán hoặc đã bị hủy" });
                // Kiểm tra thời gian check-in
                var loTrinh = db.LOTRINHs.FirstOrDefault(lt => lt.MACB == ve.MACB);
                if (loTrinh == null)
                    return Json(new { success = false, message = "Không tìm thấy lộ trình" });
                var now = DateTime.Now;
                var thoiGianCheckInBatDau = loTrinh.GIOCATCANH.AddHours(-24);
                var thoiGianCheckInKetThuc = loTrinh.GIOCATCANH.AddHours(-1);
                if (now < thoiGianCheckInBatDau)
                    return Json(new { success = false, message = "Chưa đến thời gian check-in (24h trước giờ bay)" });
                if (now > thoiGianCheckInKetThuc)
                    return Json(new { success = false, message = "Đã hết thời gian check-in (1h trước giờ bay)" });
                // Kiểm tra đã check-in chưa
                var checkIn = db.CHECKINs.FirstOrDefault(ci => ci.MAVE == maVe);

                if (checkIn != null)
                {
                    // Nếu đã có record, cập nhật trạng thái
                    if (checkIn.TRANGTHAI != null && (checkIn.TRANGTHAI == "Đã check-in" || checkIn.TRANGTHAI.StartsWith("Đã")))
                    {
                        return Json(new { success = false, message = "Vé này đã được check-in rồi" });
                    }

                    // Cập nhật trạng thái
                    checkIn.TRANGTHAI = "Đã check-in";
                    checkIn.THOIGIAN_CHECKIN = DateTime.Now;
                }
                else
                {
                    string timePart = DateTime.Now.Ticks.ToString();
                    string maCheckIn = "CI" + timePart.Substring(timePart.Length - 8);

                    // Tạo record check-in mới
                    var newCheckIn = new CHECKIN
                    {
                        MACHECKIN = maCheckIn,
                        MAVE = maVe,
                        MAKH = khachHang.MAKH,
                        MACB = ve.MACB,
                        TRANGTHAI = "Đã check-in",
                        THOIGIAN_CHECKIN = DateTime.Now
                    };

                    db.CHECKINs.Add(newCheckIn);
                }
                db.SaveChanges();
                return Json(new
                {
                    success = true,
                    message = "Check-in thành công!",
                    redirectUrl = Url.Action("CheckIn", "User", new { filter = "checkedin" })
                });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = "Lỗi: " + ex.Message });
            }
        }

        // Xem thẻ lên máy bay (Read-only)
        public ActionResult XemTheLenMayBay(string maVe)
        {
            var khachHang = Session["UserName"] as KHACHHANG;
            if (khachHang == null)
                return RedirectToAction("DangNhap");
            if (string.IsNullOrEmpty(maVe))
                return RedirectToAction("CheckIn");
            // Lấy thông tin vé
            var ve = db.VEMAYBAYs.FirstOrDefault(v => v.MAVE == maVe);
            if (ve == null)
                return RedirectToAction("CheckIn");
            // Kiểm tra vé thuộc về khách hàng
            var phieuDatVe = (from ct in db.CHITIETVEs
                              join pdv in db.PHIEUDATVEs on ct.MAPHIEU equals pdv.MAPHIEU
                              join gh in db.GIOHANGs on pdv.MAGH equals gh.MAGH
                              where ct.MAVE == maVe && gh.MAKH == khachHang.MAKH
                              select pdv).FirstOrDefault();
            if (phieuDatVe == null)
                return RedirectToAction("CheckIn");
            // Lấy thông tin chi tiết
            var chuyenBay = db.CHUYENBAYs.FirstOrDefault(cb => cb.MACB == ve.MACB);
            var loTrinh = db.LOTRINHs.FirstOrDefault(lt => lt.MACB == ve.MACB);
            var sbDi = db.SANBAYs.FirstOrDefault(s => s.MASB == loTrinh.SBDI);
            var sbDen = db.SANBAYs.FirstOrDefault(s => s.MASB == loTrinh.SBDEN);
            var ghe = db.GHEs.FirstOrDefault(g => g.MAGHE == ve.MAGHE);
            var hangGheGia = db.HANGGHE_GIA.FirstOrDefault(hg => hg.MAHG == ve.MAHG);
            var checkIn = db.CHECKINs.FirstOrDefault(ci => ci.MAVE == ve.MAVE);
            // Lấy thông tin hành khách
            string tenghe = ghe?.TENGHE;
            var ghk = db.GIOHANG_HANHKHACH
                .FirstOrDefault(hk => hk.MAGH == phieuDatVe.MAGH &&
                                     tenghe != null && hk.SOGHE == tenghe);
            // Tính thời gian bay
            var timeSpan = loTrinh.GIOHACANH - loTrinh.GIOCATCANH;
            var thoiGianBay = timeSpan.Hours > 0
                ? $"{timeSpan.Hours}h {timeSpan.Minutes:D2}m"
                : $"{timeSpan.Minutes}m";
            var model = new CheckInViewModel
            {
                MaVe = ve.MAVE,
                MaCB = ve.MACB,
                MaGhe = ve.MAGHE,
                SoGhe = ghe?.TENGHE ?? "N/A",
                HangGhe = hangGheGia?.HANGGHE ?? "Phổ thông",
                SanBayDiMa = sbDi?.MASB,
                SanBayDiTen = sbDi?.TENSB,
                SanBayDiThanhPho = sbDi?.THANHPHO,
                SanBayDenMa = sbDen?.MASB,
                SanBayDenTen = sbDen?.TENSB,
                SanBayDenThanhPho = sbDen?.THANHPHO,
                GioCatCanh = loTrinh.GIOCATCANH,
                GioHaCanh = loTrinh.GIOHACANH,
                ThoiGianBay = thoiGianBay,
                TenHanhKhach = ghk?.TENHANHKHACH ?? khachHang.TENKH,
                GioiTinh = ghk?.GIOITINH ?? khachHang.GTINH,
                NgaySinh = ghk?.NGAYSINH ?? khachHang.NGSINH,
                Email = ghk?.EMAIL ?? khachHang.EMAIL,
                SDT = khachHang.SDT,
                QuocGia = khachHang.QUOCGIA,
                GiaVe = ve.GIAVE,
                TrangThaiCheckIn = checkIn?.TRANGTHAI ?? "Chưa check-in",
                ThoiGianCheckIn = checkIn?.THOIGIAN_CHECKIN,
                DaCheckIn = checkIn != null && checkIn.TRANGTHAI != null && (checkIn.TRANGTHAI == "Đã check-in" || checkIn.TRANGTHAI.StartsWith("Đã")),
                HangLyXachTay = ghk?.HANGLY_XACHTAY ?? 0,
                HangLyKyGui = ghk?.HANHLYKYGUI ?? 0
            };
            return View(model);
        }

        // Check-in cho khách hàng chưa đăng nhập
        public ActionResult CheckInNgoai()
        {
            return View();
        }
        public ActionResult Ve()
        {
            return View();
        }
        [HttpPost]
        public ActionResult ThanhToanOnline(string maGH, string maCB, string payment_method)
        {
            var khachHang = Session["UserName"] as KHACHHANG;
            if (khachHang == null)
                return RedirectToAction("DangNhap");

            var tongTien = db.Database.SqlQuery<decimal>(
                "SELECT dbo.FN_TinhTongTien(@maGH, @maCB)",
                new SqlParameter("@maGH", maGH),
                new SqlParameter("@maCB", maCB)
            ).FirstOrDefault();


            ViewBag.MaGH = maGH;
            ViewBag.MaCB = maCB;
            ViewBag.TongTien = tongTien.ToString("N0");
            ViewBag.TenKhachHang = khachHang.TENKH;

            return View("DemoVNPay");
        }
        [HttpPost]
        public ActionResult XacNhanThanhToanDemo(string maGH, string maCB, string result)
        {
            var khachHang = Session["UserName"] as KHACHHANG;
            if (khachHang == null)
                return RedirectToAction("DangNhap");

            if (result == "success")
            {
                var chiTiet = db.GIOHANG_CHITIET.FirstOrDefault(x => x.MAGH == maGH && x.MACB == maCB);
                if (chiTiet != null && chiTiet.THOIGIANGIU < DateTime.Now)
                {
                    db.Database.ExecuteSqlCommand("EXEC sp_DonVeHetHan");
                    TempData["Error"] = "Giỏ hàng đã hết hạn giữ chỗ (Quá 15 phút). Vui lòng đặt lại!";
                    return RedirectToAction("TrangChu");
                }
                
                TaoVe(maGH, maCB);
                db.Database.ExecuteSqlCommand("EXEC SP_ThanhToanGioHang @p0", maGH);


                TempData["PaymentSuccess"] = true;
                TempData["PaymentMethod"] = "VNPay (Demo)";
                TempData["TransactionNo"] = "DEMO" + DateTime.Now.ToString("yyyyMMddHHmmss");

                return RedirectToAction("VeCuaToi");
            }
            else
            {
                TempData["Error"] = "Bạn đã hủy giao dịch";
                return RedirectToAction("ThanhToan", new { ids = maGH, cb = maCB });
            }
        }

    }
}