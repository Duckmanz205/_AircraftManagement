Feature: Payment

  Scenario: TC31 - Xem tóm tắt thanh toán
    Given Tôi đã chọn ghế và nhập thông tin khách
    Then Trang thanh toán hiển thị đúng lộ trình, số ghế và tổng tiền

  Scenario: TC32 - Thanh toán VNPay Demo thành công
    Given Tôi đang ở cổng VNPay Demo 
    When Tôi nhấn "Xác nhận thanh toán thành công"
    Then Hệ thống ghi nhận trạng thái thanh toán trong DB 
    And Chuyển hướng về trang "Vé của tôi"

  Scenario: TC33 - Hủy giao dịch thanh toán
    When Tôi nhấn "Hủy giao dịch" tại cổng Demo
    Then Hệ thống báo lỗi thanh toán thất bại và không xuất vé 

  Scenario: TC34 - Thanh toán nhiều vé cùng lúc
    Given Tôi có nhiều vé ở trạng thái "Chưa thanh toán"
    When Tôi chọn 2 vé và nhấn thanh toán hàng loạt
    Then Tổng tiền tại VNPay Demo là tổng của 2 vé đó 

  Scenario: TC35 - Kiểm tra logic tính tiền từ Database
    When Hệ thống gọi Function FN_TinhTongTien 
    Then Kết quả trả về phải khớp với tổng tiền hiển thị trên UI