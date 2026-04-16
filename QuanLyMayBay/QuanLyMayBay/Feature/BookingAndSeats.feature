Feature: Booking and Seats

  Scenario: TC24 - Bắt buộc nhập số lượng hành khách
    Given Tôi nhấn "Chọn chuyến" nhưng chưa nhập số người
    Then Modal yêu cầu nhập số hành khách xuất hiện 

  Scenario: TC25 - Chọn ghế đúng số lượng
    Given Chuyến bay có 2 hành khách
    When Tôi chọn ghế "12A" và "12B" còn trống
    Then Hệ thống cho phép nhấn "Tiếp tục" sang bước thanh toán

  Scenario: TC26 - Cố gắng chọn ghế đã có người đặt
    When Tôi nhấn vào ghế màu xám (occupied)
    Then Không có ghế nào được chọn thêm 

  Scenario: TC27 - Chọn ghế vượt quá số khách
    Given Chuyến bay có 1 hành khách
    When Tôi cố gắng chọn 2 ghế
    Then Hệ thống hiển thị Alert báo quá giới hạn 

  Scenario: TC28 - Bỏ trống thông tin hành khách
    When Tôi để trống các trường bắt buộc tại form thông tin khách
    Then Hệ thống báo lỗi tại các trường chưa nhập

  Scenario: TC29 - Mua thêm hành lý ký gửi
    When Tôi chọn thêm gói hành lý "20kg" giá 500,000 VNĐ
    Then Tổng tiền thanh toán tăng thêm 500,000 VNĐ 

  Scenario: TC30 - Chọn ghế hạng Thương gia
    When Tôi chọn một ghế hạng Thương gia (màu cam)
    Then Giá vé được tính theo đơn giá hạng ghế đặc biệt