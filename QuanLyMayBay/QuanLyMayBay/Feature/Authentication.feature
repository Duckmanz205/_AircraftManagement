Feature: Authentication
    Để sử dụng dịch vụ đặt vé hoặc quản trị hệ thống
    Người dùng và Nhân viên cần phải thực hiện các bước xác thực tài khoản

  Scenario: TC01 - Đăng ký tài khoản thành công
    Given Tôi đang ở trang Đăng ký
    When Tôi nhập Họ tên là "Nguyễn Văn A"
    And Tôi nhập Email là "test@gmail.com"
    And Tôi nhập Số điện thoại là "0912345678"
    And Tôi nhập Mật khẩu là "123456"
    And Tôi nhập Xác nhận mật khẩu là "123456"
    And Tôi nhấn nút "Đăng Ký"
    Then Hệ thống hiển thị thông báo "Tạo tài khoản thành công"
    And Chuyển hướng sang trang đăng nhập

  Scenario Outline: Đăng ký không thành công - Dữ liệu không hợp lệ
    Given Tôi đang ở trang Đăng ký
    When Tôi nhập dữ liệu: <HoTen>, <Email>, <SDT>, <Pass>, <Confirm>
    And Tôi nhấn nút "Đăng Ký"
    Then Hệ thống hiển thị lỗi: "<ErrorMessage>"
    Examples:
      | Case | HoTen          | Email        | SDT        | Pass   | Confirm | ErrorMessage                       |
      | TC02 | ""             | "a@mail.com" | 0912345678 | 123456 | 123456  | "Vui lòng nhập họ và tên"          |
      | TC03 | "Nguyễn Văn A" | "test.com"   | 0912345678 | 123456 | 123456  | "Email không hợp lệ"               |
      | TC04 | "Nguyễn Văn A" | "a@mail.com" | 012345678  | 123456 | 123456  | "Số điện thoại phải gồm 10 chữ số" |
      | TC05 | "Nguyễn Văn A" | "a@mail.com" | 0912345678 | 12345  | 12345   | "Mật khẩu phải có ít nhất 6 ký tự" |
      | TC06 | "Nguyễn Văn A" | "a@mail.com" | 0912345678 | 123456 | 123457  | "Mật khẩu xác nhận không khớp"     |

  Scenario: TC07 - Đăng nhập Người dùng thành công
    Given Tôi đang ở trang Đăng nhập và chọn tab "Người dùng"
    When Tôi nhập Email là "test@gmail.com" và Mật khẩu "123456"
    And Tôi nhấn nút "Đăng nhập"
    Then Hệ thống đăng nhập thành công và hiển thị tên "Nguyễn Văn A" trên Header

  Scenario: TC08 - Đăng nhập thất bại do sai mật khẩu
    Given Tôi đang ở trang Đăng nhập
    When Tôi nhập Email đúng nhưng sai mật khẩu "wrongpass"
    And Tôi nhấn nút "Đăng nhập"
    Then Hệ thống hiển thị thông báo lỗi xác thực

  Scenario: TC09 - Đăng nhập Admin thành công
    Given Tôi đang ở trang Đăng nhập và chọn tab "Quản trị viên"
    When Tôi nhập Mã NV "NV001" và Mật khẩu "123456"
    And Tôi nhấn nút "Đăng nhập"
    Then Hệ thống chuyển hướng vào trang Dashboard Admin 

  Scenario: TC10 - Đăng xuất tài khoản
    Given Tôi đang đăng nhập vào hệ thống
    When Tôi nhấn nút "Đăng xuất"
    And Tôi xác nhận đăng xuất tại hộp thoại confirm
    Then Session bị hủy và tôi được đưa về trang chủ