using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace QuanLyMayBay.Models.Admin
{
    /// <summary>
    /// ViewModel for country statistics from fn_ThongKeKhachTheoQuocGia() SQL function
    /// Maps to the result of: SELECT * FROM fn_ThongKeKhachTheoQuocGia()
    /// </summary>
    public class ThongKeQuocGiaViewModel
    {
        public string QUOCGIA { get; set; }

        public int SOKHACH { get; set; }
    }
}
