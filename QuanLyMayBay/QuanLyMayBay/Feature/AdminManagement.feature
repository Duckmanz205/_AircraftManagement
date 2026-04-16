Feature: Admin Management

  Scenario: TC41 - Thêm mới chuyến bay
    Given Tôi đăng nhập quyền Admin 
    When Tôi nhập thông tin chuyến bay mới và nhấn Lưu
    Then Chuyến bay mới được thêm vào bảng CHUYENBAY 

  Scenario: TC42 - Cập nhật trạng thái chuyến bay
    Given Chuyến bay đang ở trạng thái "Đúng giờ"
    When Tôi đổi trạng thái sang "Trễ chuyến"
    Then Thông tin được cập nhật đồng bộ cho cả Admin và User 

  Scenario: TC43 - Sao lưu Database
    When Admin nhấn nút "Sao lưu ngay" tại trang Cài đặt 
    Then File .bak được tạo thành công trong thư mục App_Data 

  Scenario: TC44 - Phục hồi Database
    When Admin chọn file backup và nhấn "Phục hồi"
    Then Hệ thống thực thi lệnh RESTORE DATABASE trong SQL 
    And Hiển thị thông báo phục hồi thành công

  Scenario: TC45 - Sửa thông tin nhân sự
    When Tôi cập nhật chức vụ cho nhân viên NV002 thành "Giám đốc" 
    And Nhấn Lưu
    Then Mã chức vụ (MACV) trong bảng NHANVIEN được cập nhật thành "CV09" 