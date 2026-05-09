Feature: Profile Management

  Scenario: TC11 - Cập nhật Họ tên thành công
    Given Tôi đang ở trang Hồ sơ cá nhân
    When Tôi sửa Họ tên thành "Nguyễn Văn B"
    And Tôi nhấn "Lưu thay đổi"
    Then Hệ thống cập nhật bảng KHACHHANG 
    And Hiển thị tên mới trên thanh điều hướng

  Scenario: TC12 - Thay đổi Ảnh đại diện
    Given Tôi đang ở trang Hồ sơ
    When Tôi chọn một file ảnh "avatar.jpg" và nhấn Lưu
    Then Hệ thống lưu file vào thư mục "/Content/Images/User/" 
    And Preview ảnh hiển thị chính xác

  Scenario: TC13 - Đổi mật khẩu thành công
    Given Tôi đang ở modal Đổi mật khẩu
    When Tôi nhập MK hiện tại đúng và MK mới "654321"
    And Tôi nhấn Xác nhận
    Then Hệ thống thông báo đổi mật khẩu thành công 

  Scenario: TC14 - Đổi mật khẩu thất bại do sai mật khẩu cũ
    Given Tôi đang ở modal Đổi mật khẩu
    When Tôi nhập sai MK hiện tại
    Then Hệ thống báo lỗi mật khẩu không chính xác

  Scenario: TC15 - Kiểm tra trường Email không được sửa
    Given Tôi đang xem thông tin Hồ sơ
    Then Trường Email phải ở trạng thái chỉ đọc (readonly)