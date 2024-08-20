package ImageWriter_pkg;



class ImageWriter;

  typedef shortint WORD;
  typedef int DWORD;

  typedef struct {
    WORD  bfType    ;
    DWORD bfSize    ;
    DWORD bfReserved;
    DWORD bfOffBits ;
  } BITMAPFILEHEADER;

  typedef struct {
    DWORD biSize         ;
    DWORD biWidth        ;
    DWORD biHeight       ;
    WORD  biPlanes       ;
    WORD  biBitCount     ;
    DWORD biCompression  ;
    DWORD biSizeImage    ;
    DWORD biXPelsPerMeter;
    DWORD biYPelsPerMeter;
    DWORD biClrUsed      ;
    DWORD biClrImportant ;
  }  BITMAPINFOHEADER;

  BITMAPFILEHEADER header;
  BITMAPINFOHEADER info  ;

  logic [23:0] image[][];

  int aligning_bytes_qnty;

  task init(DWORD biWidth, DWORD biHeight);
    header = '{
      bfType     : 16'h4D42,
      bfSize     : 32'h36 + (biWidth*biHeight*3),
      bfReserved : '0,
      bfOffBits  : 32'h36
    };

    info = '{
      biSize          : 32'h28,
      biWidth         : biWidth,
      biHeight        : biHeight,
      biPlanes        : 16'h1,
      biBitCount      : 16'h18,
      biCompression   : 32'h0,
      biSizeImage     : 32'h0,
      biXPelsPerMeter : 32'h0,
      biYPelsPerMeter : 32'h0,
      biClrUsed       : 32'h0,
      biClrImportant  : 32'h0
    };
    aligning_bytes_qnty = ( biWidth*3 )%4;
    image = new [biHeight];
    foreach (image[i]) begin
      image[i] = new [biWidth];
    end
  endtask : init

  task save_file(string file_name);
    int file;
    file = $fopen(file_name,"wb");
    if (file) $display("File was opened(%x)", file);
    else      $display("File was NOT opened");
    write_word (file, header.bfType     );
    write_dword(file, header.bfSize     );
    write_dword(file, header.bfReserved );
    write_dword(file, header.bfOffBits  );
    write_dword(file, info.biSize           );
    write_dword(file, info.biWidth          );
    write_dword(file, info.biHeight         );
    write_word (file, info.biPlanes         );
    write_word (file, info.biBitCount       );
    write_dword(file, info.biCompression    );
    write_dword(file, info.biSizeImage      );
    write_dword(file, info.biXPelsPerMeter  );
    write_dword(file, info.biYPelsPerMeter  );
    write_dword(file, info.biClrUsed        );
    write_dword(file, info.biClrImportant   );

    for (int row = 0; row < info.biHeight; row++)begin
      for (int col = 0; col < info.biWidth; col++)begin
        write_pixel(file, image[(info.biHeight-1) - row][col]);
      end

      for (int i = 0; i < aligning_bytes_qnty; i++) begin
        $fwrite(file,"%c", 8'd0);
      end

    end

    $fclose(file);
  endtask : save_file

  task write_word(int file, shortint data);
    $fwrite(file,"%c%c", data[0 +: 8], data[8 +: 8]);
  endtask : write_word

  task write_dword(int file, int data);
    $fwrite(file,"%c%c%c%c", data[0 +: 8], data[8 +: 8], data[16 +: 8], data[24 +: 8]);
  endtask : write_dword

  task write_pixel(int file, logic [23:0] data);
    $fwrite(file,"%c%c%c", data[0 +: 8], data[8 +: 8], data[16 +: 8]);
  endtask : write_pixel

  task fill();
    for (int row = 0; row < info.biHeight; row++)
      for (int col = 0; col < info.biWidth; col++)
        add_pixel('1, row, col);
    
  endtask

  task add_pixel(logic [23:0] pix, int row, int col);
    image[row][col] = pix;
  endtask

endclass : ImageWriter

endpackage