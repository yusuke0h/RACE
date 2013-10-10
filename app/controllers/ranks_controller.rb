# encoding: utf-8

class RanksController < ApplicationController
  def new
  end

  def create
    if params[:rank].nil?
      redirect_to new_rank_path, :notice => 'ファイルを1つ以上選択してください'
      return
    end
    files = []
    params[:rank][:files].each do |file|
      files << { :file => open(file.tempfile), :name => file.original_filename }
    end
    @html = make_report(files).string
    render :layout => false
  end

  private

  def make_report(files)
      out = StringIO.new

      Encoding.default_external = Encoding::UTF_8

      out.puts(<<HTML)
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8" />
        <title>Report</title>
        <style>
          * {
              font-family: sans-serif;
          }
          html, body {
              margin: 0;
              padding: 0;
              height: 100%;
              overflow: hidden;
          }
          .hbox {
              display: -webkit-flex;
              display:    -moz-flex;
              display:         flex;
              -webkit-flex-direction: row;
                 -moz-flex-direction: row;
                      flex-direction: row;
          }
          .vbox {
              display: -webkit-flex;
              display:    -moz-flex;
              display:         flex;
              -webkit-flex-direction: column;
                 -moz-flex-direction: column;
                      flex-direction: column;
          }
          .separator {
              -webkit-flex: 0 0 8px;
                 -moz-flex: 0 0 8px;
                      flex: 0 0 8px;
          }
          #outmost {
              height: 100%;
          }
          #links {
              width: 100%;
              padding: 0.2em 0.5em;
              background-color: #252525;
              box-shadow: 0 0 8px black;
              -webkit-flex: 0 0 auto;
                 -moz-flex: 0 0 auto;
                      flex: 0 0 auto;
          }
          #links > a {
              color: #ff7f2a;
              text-decoration: none;
          }
          #links > a:hover {
              text-shadow: 0px 0px 8px #f60;
          }
          #links > a:before {
              content: ">";
          }
          #main {
              overflow-y: scroll;
              -webkit-flex: 1 1;
                 -moz-flex: 1 1;
                      flex: 1 1;
          }
          .table-container-content-width {
              margin-right: 8px;
              -webkit-flex: 0 0 auto;
                 -moz-flex: 0 0 auto;
                      flex: 0 0 auto;
          }
          .table-container {
              margin-right: 8px;
              -webkit-flex: 1 1;
                 -moz-flex: 1 1;
                      flex: 1 1;
          }
          table {
              border-collapse: collapse;
              width: 100%;
          }
          thead {
              border-bottom: 2px solid black;
          }
          col.term {
          }
          col.weight {
          }
          tbody tr:nth-child(odd) {
              background: white;
          }
          tbody tr:nth-child(even) {
              background: #ddd;
          }
          tbody th.text-cell, td.text-cell {
              text-align: left;
          }
          tbody th.num-cell, td.num-cell {
              text-align: right;
          }
          tbody tr.new {
              background-color: #fea;
          }
          tbody tr.higher {
              background-color: #faa;
          }
          tbody tr.lower {
              background-color: #aaf;
          }
          tbody tr.tie {
              background-color: white;
          }
          tbody tr.focused {
              font-weight: bold;
              color: #228B22;
          }
        </style>
        <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.10.2/jquery.min.js"></script>
      </head>
      <body>
HTML

      out.puts('<div id="outmost" class="vbox">')
      out.puts('<div id="main">')
      out.puts('<div class="vbox">')

      is_hbox_open = false
      files.each_with_index {|file, i|
        fp = file[:file]
        name = file[:name]
        if fp =~ /^#(\S*)$/
        else
          unless is_hbox_open
            out.puts('<div id="exp-noname" class="hbox">')
            is_hbox_open = true
          end

          data = IO.readlines(fp).map {|l| tw = l.split("\t"); [2, 3].include?(tw.length) ? tw : nil }.compact

          # if (i != 0) {
          #   out.puts('<div class="separator"></div>');
          # }
          # out.puts('<div class="table-container">')
          out.puts('<div class="table-container-content-width">')
          out.puts('<table>')
          out.puts('<colgroup><col class="term"><col class="weight"></colgroup>')
          out.puts('<thead>')
          out.puts("<tr><th colspan=\"2\">#{CGI.escapeHTML(File.basename(name))}</th></tr>")
          # out.puts("<tr><th colspan=\"2\">#{CGI.escapeHTML(fp)}</th></tr>")
          out.puts('<tr><th>-</th></tr>');
          out.puts('<tr><th>XXX</th><th>Weight</th></tr>');
          out.puts('</thead>');
          out.puts('<tbody>');
          data.each_with_index {|(term, weight, *rest),j|
              id = "#{i}_#{j}"
              words = rest.length > 0 ? rest[0] : nil
              out.print(<<HTML)
                  <tr>
                  <td class="term text-cell">
                      <span onclick="$('\##{id}').css('display', $('\##{id}').css('display') === 'block' ? 'none' : 'block')">
                          #{CGI.escapeHTML(term)}
                      </span>
HTML
              if words
                  out.puts (<<-HTML)
                   <div onclick="$('\##{id}').css('display','none')" style="display: none" id="#{id}">
                   <ol>
                  HTML
                  words.split(",").each do |word|
                      out.print "<li>",word,"</li>","\n" if word.strip.size > 0
                  end
                  out.puts (<<-HTML)
                  </ol>
                  </div>
                  HTML
              end
              out.puts(<<HTML)
                  </td>
                  <td class="weight num-cell">
                  #{CGI.escapeHTML(weight[0..4])}
                  </td>
                  </tr>
HTML
          }
          out.puts('</tbody></table>');
          out.puts('</div>')
        end
      }
      out.puts('</div>') if is_hbox_open
      out.puts('</div>')  # div.vbox
      out.puts('</div>')  # div#main
      out.puts('</div>')  # div#outmost
      out.puts(<<HTML)
        <script>
          $().ready(function() {
              "use strict";

              $('table').on('click', function(e) {
                  if ($(this).hasClass('current-standard')) {
                      $('table, tr').removeClass('current-standard new higher lower tie');
                  }
                  else {
                      $('table, tr').removeClass('current-standard new higher lower tie');

                      var ranks = {};
                      $(this).find('td.term').each(function(i, td) {
                          var w = $(td).find("span").text();
                          ranks[w] = i;
                      });

                      $(this).addClass('current-standard');
                      $(this).find("thead > tr:nth-child(2) > th").text("-");
                      $(this).parent().parent().find('table:not(.current-standard)').each(function(_, table) {
                          var sum_d = 0.0;
                          $(table).find('td.term').each(function(i, td) {
                              var w = $(td).find("span").text();

                              if (!ranks.hasOwnProperty(w)) {
                                  $(td).parent().addClass('new');
                                  sum_d += Math.pow( $(table).find('td.term').length, 2);
                              }
                              else if (i < ranks[w]) {
                                  $(td).parent().addClass('higher');
                                  sum_d += Math.pow( i - ranks[w], 2);
                              }
                              else if (i > ranks[w]) {
                                  $(td).parent().addClass('lower');
                                  sum_d += Math.pow( i - ranks[w], 2);
                              }
                              else {
                                  $(td).parent().addClass('tie');
                              }
                          });
                          var n = $(table).find('td.term').length;
                          var p = 1.0 - ((6.0 * sum_d) / (Math.pow(n, 3) - n));
                          table.rows[1].cells[0].innerText = p;
                          table.rows[1].cells[0].style.color = "#228B22";
                      });
                  }
              });
              $('tbody tr').on('mouseover', function(e) {
                  if (e.shiftKey) {
                      $('tr').removeClass('focused');
                      var w = $(this).find('td.term span').text();
                      $(this).parent().parent().parent().parent().find('tr').filter(function() { return $(this).find('td.term span').text() === w; }).addClass('focused');
                  }
              });
          });
        </script>
      </body>
      </html>
HTML
      return out
  end

end
