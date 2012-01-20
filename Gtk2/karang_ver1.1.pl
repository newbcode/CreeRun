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
my $label1 = $builder->get_object( "label1" );
my $entry = $builder->get_object( "entry3" );
my $text_view = $builder->get_object( "textview1" );
#my $pix_buf->new_from_file("lovely.jpg");
my $text_buffer = $text_view->get_buffer; 
my $entry_1 = $builder->get_object( "entry1" );
my $entry_2 = $builder->get_object( "entry2" );
my $entry_3 = $builder->get_object( "entry3" );
my $entry_4 = $builder->get_object( "entry4" );
my $dialog = $builder->get_object( "messagedialog1" );
#$window->signal_connect('delete_event' => sub { Gtk2->main_quit; });
$window->signal_connect( 'delete_event' => \&quit );
$window->signal_connect( 'destroy' => \&quit );
#$entry_3->set_text("80150170117");

sub quit { Gtk2->main_quit };

$builder->connect_signals( undef );
$window->show();
$builder = undef;
Gtk2->main();
    
sub cb_destroy {
    %datas = ();
    $text_buffer->set_text("");
    $entry_1->set_text("");
}
    
sub cb_add_clicked {
    my $get_str = $entry_3->get_text();
    my ($get_num) = $get_str =~  m{http://hello_karang.blog.me/(\d+)};
    my $get_url =
        "http://blog.naver.com/CommentList.nhn?blogId=hello_karang&logNo=$get_num&currentPage=&isMemolog=false&focusingCommentNo=&showLastPage=true";
# push @people, $get_str;
#    my $people_join = join ("\n", @people);
#    $text_buffer->set_text("$people_join");
#    $entry_3->set_text("");
    system "wget", "-O", "$get_num", "$get_url"; 
    my $txt = qx | cat $get_num|;
    $txt = Encode::decode("euc-kr", $txt);
    my @names = $txt =~ m{ writerNickname : "(.*?)" }gsm;
    my @texts = $txt =~ m{<dd .*? value="(.*?)" />.*?</dd>}gsm;
    my $n_end = $#names;
    my $cnt;
    my $people = 1;
    my $file = 'nicks.txt';
    
    open my $fh, '>', $file or die "Can't open file $file : $!\n";

    for ($cnt=0;$cnt<$n_end;$cnt++) {
         $datas{$names[$cnt]} = $texts[$cnt];
#         say 'now in hash syntax';
#         print "$datas{$names[$cnt]} = $texts[$cnt]";
    }
    foreach my $key ( keys %datas) {
            if ( $datas{$key} =~ m !응모|도전|새이웃|참여|신청|줄서봐|^http://!) { 
                say {$fh} $key;
                push @ids, $key;
                $people++;
#                say 'now in if syntax';
    }
    }
    close $fh;

    my $content = qx | cat nicks.txt|;
    $content = Encode::decode("utf-8", $content);
    $text_buffer->set_text("$content");
    $people -= 1;
    $entry_1->set_text($people);
    $entry_3->set_text("");

}
sub cb_lotto_clicked {
    my $cnt;
    my $num = $entry_4->get_text();
    my @ids = shuffle @ids;
    for ($cnt=0;$cnt<$num;$cnt++) {
        $entry_2->set_text($ids[$cnt]);
        $dialog->format_secondary_text("$ids[$cnt]" . "님 축하드립니다");
        $dialog->run;
        $dialog->hide
    }
}
