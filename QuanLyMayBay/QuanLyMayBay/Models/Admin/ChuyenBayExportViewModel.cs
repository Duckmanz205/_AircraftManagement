using System;

namespace QuanLyMayBay.Models.Admin
{
    public class ChuyenBayExportViewModel
    {
        public string MaChuyenBay { get; set; }
        public string TenMayBay { get; set; }
        public string Hang { get; set; }
        public string TrangThai { get; set; }
        public string SanBayDi { get; set; }
        public string SanBayDen { get; set; }
        public DateTime? GioCatCanh { get; set; }
        public DateTime? GioHaCanh { get; set; }
    }
}
