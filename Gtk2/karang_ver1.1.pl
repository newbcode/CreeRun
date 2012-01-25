#!/usr/bin/env perl

use 5.010;
use utf8;
use strict;
use warnings;
binmode(STDOUT, ":utf8");

use Glib qw{ TRUE FALSE };
use Gtk2 qw{ -init };
use List::Util qw( shuffle );
use Encode;
use Data::Dumper;

#후보 명단에 들어갈 문자의 배열선언
my @people;
my %datas;
my @ids;
#builder 호출로 윈도우 가져오기
my $builder = Gtk2::Builder->new();
#glade 파일 가져오기
$builder->add_from_file( "up_gift.glade" )
    or die "Error loading GLADE file";
#메인 윈도우 가져오기
my $window = $builder->get_object( "window1");
#라벨 가져오기
my $label1 = $builder->get_object( "label1" );
#스크랩(URL)부분 가져오기
my $entry = $builder->get_object( "entry3" );
#닉네임이 보여지는 텍스트 박스 가져오기
my $text_view = $builder->get_object( "textview1" );
my $text_buffer = $text_view->get_buffer; 
my $entry_1 = $builder->get_object( "entry1" );
my $entry_2 = $builder->get_object( "entry2" );
my $entry_3 = $builder->get_object( "entry3" );
my $entry_4 = $builder->get_object( "entry4" );
my $dialog = $builder->get_object( "messagedialog1" );
#$window->signal_connect('delete_event' => sub { Gtk2->main_quit; });
# PoPup Dig 부분
$window->signal_connect( 'delete_event' => \&quit );
$window->signal_connect( 'destroy' => \&quit );

sub quit { Gtk2->main_quit };

$builder->connect_signals( undef );
$window->show();
$builder = undef;
Gtk2->main();
    
#삭제 버튼
sub cb_destroy {
#Hash 부분 초기화
    %datas = ();
#Text Buffer 초기화
    $text_buffer->set_text("");
#URL부분 초기화
    $entry_1->set_text("");
}
    
#확인 버튼
sub cb_add_clicked {
#확인부분의 텍스트 가져오기
    my $get_str = $entry_3->get_text();
#URL부분의 URL중 숫자만 가져오기
    my ($get_num) = $get_str =~  m{http://hello_karang.blog.me/(\d+)};
#URL 부분의 숫자만 가져와서 댓글 페이지 다운로드
    my $get_url =
        "http://blog.naver.com/CommentList.nhn?blogId=hello_karang&logNo=$get_num&currentPage=&isMemolog=false&focusingCommentNo=&showLastPage=true";
#시스템 명령어로 댓글페이지 다운로드
    system "wget", "-O", "$get_num", "$get_url"; 
#cat으로 다운로드된 HTML페이를 통째로 열기
    my $txt = qx | cat $get_num|;
#다운로드된 euc-kr -> uft-8로 decode하기
    $txt = Encode::decode("euc-kr", $txt);
#pcre로 댓글을 단 모든 닉네임 가져오기
    my @names = $txt =~ m{ writerNickname : "(.*?)" }gsm;
#댓글의 내용을 가져오기 
    my @texts = $txt =~ m{<dd .*? value="(.*?)" />.*?</dd>}gsm;
#array의 마지막 첨자 가져오기(for문을 돌리기 위해)
    my $n_end = $#names;
    my $cnt;
    my $people = 1;
    my $file = 'nicks.txt';
#open으로 $file을 열기
    open my $fh, '>', $file or die "Can't open file $file : $!\n";
    
#hash를 만들기 위한 for문(Nick->댓글내용)
    for ($cnt=0;$cnt<$n_end;$cnt++) {
#%datas hash구조에 맞게 첫번째 닉네임부터 $texts의 내용을 넣는다.
         $datas{$names[$cnt]} = $texts[$cnt];
    }
#pcre로 댓글의 내용중 아래와 같은 단어들 포함시 닉네임을 파싱한다.
    foreach my $key ( keys %datas) {
            if ( $datas{$key} =~ m !응모|도전|새이웃|참여|신청|줄서봐|^http://!) { 
                say {$fh} $key;
                push @ids, $key;
                $people++;
    }
    }
    close $fh;

    my $content = qx | cat nicks.txt|;
#utf-8로 다시 인코딩 한다.
    $content = Encode::decode("utf-8", $content);
#text_buffer에 content의 닉네임들을 넣는다.
    $text_buffer->set_text("$content");
#0부터 시작하므로 카운트에서 -1을 한다
    $people -= 1;
#응모자수를 카운트한다.
    $entry_1->set_text($people);
    $entry_3->set_text("");

}
sub cb_lotto_clicked {
    my $cnt;
#다수의 당첨자를 위한 설정(당첨자수를 설정시 설한 수 만큼 for문을 돌려
#당첨자를 연속으로 추출한다)
    my $num = $entry_4->get_text();
#array suffle 한다.
    my @ids = shuffle @ids;
#다수의 당첨자를 위한 for문
    for ($cnt=0;$cnt<$num;$cnt++) {
        $entry_2->set_text($ids[$cnt]);
        $dialog->format_secondary_text("$ids[$cnt]" . "님 축하드립니다");
        $dialog->run;
        $dialog->hide
    }
}
