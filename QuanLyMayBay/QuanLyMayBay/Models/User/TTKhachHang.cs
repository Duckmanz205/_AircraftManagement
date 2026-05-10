using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace QuanLyMayBay.Models
{
    public class TTKhachHang
    {

        public string Seat { get; set; }           // Ghế
        public string Name { get; set; }           // Họ tên
        public string Gender { get; set; }         // Giới tính
        public string Dob { get; set; }            // Ngày sinh (string hoặc DateTime)
        public string Country { get; set; }        // Quốc gia
        public string Email { get; set; }
        public string Phone { get; set; }
        public int ?CarryOnFee { get; set; }        // Phí xách tay thêm
        public int ?CheckedFee { get; set; }        // Phí ký gửi
        public string SeatClass { get; set; }         // Hạng ghế

    }

}