Feature: Online Check-in

  Scenario: TC36 - Thực hiện Check-in thành công
    Given Tôi có vé sẵn sàng check-in
    When Tôi xác nhận các điều khoản an toàn bay 
    And Nhấn "Xác nhận Check-in"
    Then Cột DACHECKIN trong SQL chuyển thành 1 
    And Thông báo check-in thành công hiển thị

  Scenario: TC37 - Check-in sớm hơn quy định
    Given Chuyến bay khởi hành sau 48 giờ
    Then Nút Check-in hiển thị trạng thái disabled 

  Scenario: TC38 - Xem Thẻ lên máy bay
    Given Tôi đã check-in thành công
    When Tôi nhấn "Xem thẻ lên máy bay"
    Then Hiển thị mã QR và thông tin chuyến bay tại Ve.cshtml 

  Scenario: TC39 - Tra cứu Check-in cho khách vãng lai
    Given Tôi không đăng nhập
    When Tôi nhập mã vé hợp lệ tại trang Check-in ngoại 
    Then Hệ thống tìm thấy và hiển thị thông tin chuyến bay tương ứng

  Scenario: TC40 - Kiểm tra vé quá hạn check-in
    Given Chuyến bay đã cất cánh hoặc còn dưới 1 giờ khởi hành
    Then Vé được chuyển vào tab "Quá hạn"