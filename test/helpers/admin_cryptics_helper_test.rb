require "test_helper"

class AdminCrypticsHelperTest < ActionView::TestCase
  include Admin::CrypticsHelper

  test "solve_time shows seconds, minutes or hours" do
    assert_equal "—", solve_time(nil)
    assert_equal "42 s", solve_time(42)
    assert_equal "1 min 05 s", solve_time(65)
    assert_equal "12 min 00 s", solve_time(720)
    assert_equal "1 h 02 min", solve_time(3_725)
  end

  test "highlighted_clue marks whole words first and never overlaps parts" do
    cryptic = Cryptic.new(clue: "Flor con corriente de agua: ciudad santafesina",
                          definitions: [ "ciudad santafesina" ], indicators: [ "con" ],
                          material: [ "Flor", "corriente de agua" ])

    html = highlighted_clue(cryptic)

    assert_includes html, '<mark class="admin-part admin-part--indicator">con<span class="visually-hidden"> (indicador)</span></mark>'
    assert_includes html, '<mark class="admin-part admin-part--material">corriente de agua<span class="visually-hidden"> (material)</span></mark>'
    assert_includes html, "<mark class=\"admin-part admin-part--definition\">ciudad santafesina"
    assert_equal 4, html.scan("<mark").size
  end

  test "highlighted_clue escapes the clue" do
    cryptic = Cryptic.new(clue: "<b>Felino</b> o herramienta", definitions: [ "Felino" ])

    html = highlighted_clue(cryptic)

    assert_includes html, "&lt;b&gt;"
    assert_not_includes html, "<b>"
  end

  test "answer_words splits the answer into letters by word" do
    assert_equal [ %w[S E C R E T O] ], answer_words(Cryptic.new(answer: "secreto"))
    assert_equal [ %w[A B], %w[C] ], answer_words(Cryptic.new(answer: "ab c"))
  end
end
