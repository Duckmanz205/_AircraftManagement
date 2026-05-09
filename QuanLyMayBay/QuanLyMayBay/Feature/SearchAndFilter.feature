Feature: Search and Filter

  Scenario: TC16 - Tìm kiếm chuyến bay Một chiều
    Given Tôi ở trang chủ
    When Tôi chọn "Một chiều"
    And Chọn "Hà Nội" đi "TP.HCM" ngày "2024-12-15"
    And Nhấn "Tìm chuyến bay"
    Then Danh sách chuyến bay phù hợp hiển thị tại DatVe.cshtml 

  Scenario: TC17 - Tìm kiếm với điểm đi trùng điểm đến
    When Tôi chọn điểm đi và điểm đến cùng là "Hà Nội"
    Then Hệ thống yêu cầu chọn lại điểm đến khác 

  Scenario Outline: Lọc kết quả chuyến bay
    Given Tôi đang ở trang kết quả tìm kiếm
    When Tôi áp dụng bộ lọc <LoaiLoc> với giá trị <GiaTri>
    Then Danh sách chuyến bay tự động cập nhật theo tiêu chí <GiaTri>
    Examples:
      | Case | LoaiLoc            | GiaTri                     |
      | TC18 | Hãng hàng không    | "Vietnam Airlines"         |
      | TC19 | Khoảng giá         | "Dưới 2 triệu"             |
      | TC20 | Giờ bay            | "Sáng sớm (06:00 - 12:00)" |

  Scenario: TC21 - Sắp xếp theo giá thấp nhất
    When Tôi nhấn vào nút sắp xếp "Giá thấp nhất"
    Then Chuyến bay có giá rẻ nhất hiển thị ở đầu danh sách 

  Scenario: TC22 - Tìm kiếm không có kết quả
    When Tôi tìm kiếm một lộ trình không có lịch bay
    Then Hiển thị thông báo "Không có chuyến bay nào theo yêu cầu" 

  Scenario: TC23 - Nhập số hành khách vượt giới hạn
    When Tôi nhập số hành khách là 10
    Then Hệ thống ngăn chặn submit và báo lỗi tối đa 9 khách