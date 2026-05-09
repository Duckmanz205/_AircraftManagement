Feature: Statistics and Reporting

  Scenario: TC46 - Hiển thị biểu đồ doanh thu Dashboard
    Given Tôi truy cập Dashboard Admin
    Then Biểu đồ Chart.js hiển thị dữ liệu doanh thu khớp với DB 

  Scenario: TC47 - Thống kê doanh thu theo chuyến bằng SQL Cursor
    When Tôi truy cập trang Thống kê theo chuyến
    Then Dữ liệu được load từ procedure sp_ThongKeDoanhThuTheoChuyen 

  Scenario: TC48 - Xuất báo cáo ra file Excel
    When Tôi nhấn nút "Xuất Excel" 
    Then Một file .xlsx được tải xuống với đầy đủ dữ liệu thống kê 

  Scenario: TC49 - Kiểm tra bảo mật menu Admin
    Given Tôi là nhân viên không có quyền quản lý (MACV="CV01")
    Then Các menu "Quản trị hệ thống" và "Sao lưu" phải bị ẩn

  Scenario: TC50 - Xuất hóa đơn/báo cáo PDF
    When Tôi yêu cầu xuất báo cáo PDF 
    Then Hệ thống sinh file PDF dựa trên template BaoCaoPDF.cshtml 