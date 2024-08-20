`timescale 1ps/1ps

import ImageWriter_pkg::*;

module tb ();

  parameter PIX_WIDTH          = 8 ;
  parameter WEIGHT_WIDTH       = 10;
  parameter WEIGHT_FRACT_WIDTH = 5 ;
  parameter KERNEL_DIMENSION   = 3 ;
  // parameter BMP_FILE = "./test_pictures/640-480-sample.bmp";
  parameter BMP_FILE = "./test_pictures/dog.bmp";
  // parameter BMP_FILE = "./test_pictures/bitLion.bmp";
  // parameter BMP_FILE = "./test_pictures/sample2.bmp";

  logic            clk     = 0;
  logic            rst_n      ;
  logic [2:0][7:0] i_data     ;
  logic            i_valid    ;
  logic            i_sop      ;
  logic            i_eop      ;
  logic [2:0][7:0] o_data     ;
  logic [2:0]      o_valid    ;
  logic [2:0]      o_sop      ;
  logic [2:0]      o_eop      ;
  logic            ready      ;


  logic signed [KERNEL_DIMENSION-1:0][KERNEL_DIMENSION-1:0][WEIGHT_WIDTH-1:0] kernel;
  int output_col = 0, output_row=0;


  ImageWriter Writer;
  ImageWriter::BITMAPFILEHEADER header;
  ImageWriter::BITMAPINFOHEADER info  ;


  initial begin
    forever #10 clk = !clk;
  end



  conv #(
    .PIX_WIDTH         (PIX_WIDTH         ),
    .WEIGHT_WIDTH      (WEIGHT_WIDTH      ),
    .WEIGHT_FRACT_WIDTH(WEIGHT_FRACT_WIDTH),
    .KERNEL_DIMENSION  (KERNEL_DIMENSION  )
  ) inst_conv_r (
    .clk       (clk          ),
    .rst_n     (rst_n        ),
    .clk_en    (1            ),
    .i_data    (i_data [0]   ),
    .i_valid   (i_valid      ),
    .i_sop     (i_sop        ),
    .i_eop     (i_eop        ),
    .o_data    (o_data [2]   ),
    .o_valid   (o_valid[2]   ),
    .o_sop     (o_sop  [2]   ),
    .o_eop     (o_eop  [2]   ),
    .ready     (ready        ),
    .kernel    (kernel       ),
    .img_width (info.biWidth ),
    .img_heigth(info.biHeight),
    .cols_cntr (output_col   ),
    .rows_cntr (output_row   )
  );

  conv #(
    .PIX_WIDTH         (PIX_WIDTH         ),
    .WEIGHT_WIDTH      (WEIGHT_WIDTH      ),
    .WEIGHT_FRACT_WIDTH(WEIGHT_FRACT_WIDTH),
    .KERNEL_DIMENSION  (KERNEL_DIMENSION  )
  ) inst_conv_g (
    .clk       (clk          ),
    .rst_n     (rst_n        ),
    .clk_en    (1            ),
    .i_data    (i_data [1]   ),
    .i_valid   (i_valid      ),
    .i_sop     (i_sop        ),
    .i_eop     (i_eop        ),
    .o_data    (o_data [1]   ),
    .o_valid   (o_valid[1]   ),
    .o_sop     (o_sop  [1]   ),
    .o_eop     (o_eop  [1]   ),
    .kernel    (kernel       ),
    .img_width (info.biWidth ),
    .img_heigth(info.biHeight)
  );

  conv #(
    .PIX_WIDTH         (PIX_WIDTH         ),
    .WEIGHT_WIDTH      (WEIGHT_WIDTH      ),
    .WEIGHT_FRACT_WIDTH(WEIGHT_FRACT_WIDTH),
    .KERNEL_DIMENSION  (KERNEL_DIMENSION  )
  ) inst_conv_b (
    .clk       (clk          ),
    .rst_n     (rst_n        ),
    .clk_en    (1            ),
    .i_data    (i_data [2]   ),
    .i_valid   (i_valid      ),
    .i_sop     (i_sop        ),
    .i_eop     (i_eop        ),
    .o_data    (o_data [0]   ),
    .o_valid   (o_valid[0]   ),
    .o_sop     (o_sop  [0]   ),
    .o_eop     (o_eop  [0]   ),
    .kernel    (kernel       ),
    .img_width (info.biWidth ),
    .img_heigth(info.biHeight)
  );

  always_ff @(posedge clk)begin
    if (o_valid[0]) begin
      Writer.add_pixel(o_data, output_row-2, output_col-2);
    end
  end





  logic [23:0] read_pixels[][];

  int    fd  ;

  int raws = 0;
  int cols = 0;


  initial begin

    rst_n = 0;
    i_data = 0;
    i_valid= 0;
    i_sop  = 0;
    i_eop  = 0;

    #100 rst_n = 1;


    fd = $fopen(BMP_FILE,"rb");

    $fread(header,fd);

    if(header.bfType != "BM")begin
      $display("Error: The file is not BMP");
      $stop;
    end
    else begin
      $display("The BMP file is opened");
    end

    header.bfOffBits = {header.bfOffBits[0 +: 8], header.bfOffBits[8 +: 8], header.bfOffBits[16 +: 8], header.bfOffBits[24 +: 8]};
    
    $fread(info,fd);
    if(info.biBitCount != 16'h1800)begin
      $display("Error: biBitCount must be 24");
      $stop;
    end

    info.biWidth = {info.biWidth[0 +: 8], info.biWidth[8 +: 8], info.biWidth[16 +: 8], info.biWidth[24 +: 8]};
    info.biHeight = {info.biHeight[0 +: 8], info.biHeight[8 +: 8], info.biHeight[16 +: 8], info.biHeight[24 +: 8]};

    repeat(header.bfOffBits - 'h36)
      $fgetc(fd);


    read_pixels = new [info.biHeight];
    foreach (read_pixels[i]) begin
      read_pixels[i] = new [info.biWidth];
    end

    foreach (read_pixels[x,y]) begin
      read_pixels[(info.biHeight-1) - x][y] = {8'($fgetc(fd)),8'($fgetc(fd)),8'($fgetc(fd))};
    end

    $fclose(fd);

    $system("mkdir results");


    Writer = new;
    Writer.init(info.biWidth-2, info.biHeight-2);

kernel = {{WEIGHT_WIDTH'('d0<<WEIGHT_FRACT_WIDTH), WEIGHT_WIDTH'(10'd0<<WEIGHT_FRACT_WIDTH), WEIGHT_WIDTH'(10'd0<<WEIGHT_FRACT_WIDTH)},
          {WEIGHT_WIDTH'('d0<<WEIGHT_FRACT_WIDTH), WEIGHT_WIDTH'(10'd1<<WEIGHT_FRACT_WIDTH), WEIGHT_WIDTH'(10'd0<<WEIGHT_FRACT_WIDTH)},
          {WEIGHT_WIDTH'('d0<<WEIGHT_FRACT_WIDTH), WEIGHT_WIDTH'(10'd0<<WEIGHT_FRACT_WIDTH), WEIGHT_WIDTH'(10'd0<<WEIGHT_FRACT_WIDTH)}};


    repeat(info.biHeight)begin
      repeat(info.biWidth)begin
        @(posedge clk);
        i_sop = (cols==0) && (raws==0);
        i_data = read_pixels[raws][cols];
        i_valid = 1;
        cols++;
      end
      raws++;
      cols = 0;
    end
    i_eop = 1;
    @(posedge clk);
    i_valid = 0;
    i_eop = 0;

    #200 Writer.save_file("./results/Identity.bmp");

    raws = 0;
    cols = 0;
    wait(ready);

    kernel = {{WEIGHT_WIDTH'(-'d1<<WEIGHT_FRACT_WIDTH), WEIGHT_WIDTH'(-'d1<<WEIGHT_FRACT_WIDTH), WEIGHT_WIDTH'(-'d1<<WEIGHT_FRACT_WIDTH)},
              {WEIGHT_WIDTH'(-'d1<<WEIGHT_FRACT_WIDTH), WEIGHT_WIDTH'( 'd8<<WEIGHT_FRACT_WIDTH), WEIGHT_WIDTH'(-'d1<<WEIGHT_FRACT_WIDTH)},
              {WEIGHT_WIDTH'(-'d1<<WEIGHT_FRACT_WIDTH), WEIGHT_WIDTH'(-'d1<<WEIGHT_FRACT_WIDTH), WEIGHT_WIDTH'(-'d1<<WEIGHT_FRACT_WIDTH)}};

    repeat(info.biHeight)begin
      repeat(info.biWidth)begin
        @(posedge clk);
        i_sop = (cols==0) && (raws==0);
        i_data = read_pixels[raws][cols];
        i_valid = 1;
        cols++;
      end
      raws++;
      cols = 0;
    end
    i_eop = 1;
    @(posedge clk);
    i_valid = 0;
    i_eop = 0;


    #200 Writer.save_file("./results/edge_detection.bmp");

    kernel = {{ WEIGHT_WIDTH'('d0<<WEIGHT_FRACT_WIDTH), -WEIGHT_WIDTH'('d1<<WEIGHT_FRACT_WIDTH),  WEIGHT_WIDTH'('d0<<WEIGHT_FRACT_WIDTH)},
              {-WEIGHT_WIDTH'('d1<<WEIGHT_FRACT_WIDTH),  WEIGHT_WIDTH'('d5<<WEIGHT_FRACT_WIDTH), -WEIGHT_WIDTH'('d1<<WEIGHT_FRACT_WIDTH)},
              { WEIGHT_WIDTH'('d0<<WEIGHT_FRACT_WIDTH), -WEIGHT_WIDTH'('d1<<WEIGHT_FRACT_WIDTH),  WEIGHT_WIDTH'('d0<<WEIGHT_FRACT_WIDTH)}};

    raws = 0;
    cols = 0;
    wait(ready);
    repeat(info.biHeight)begin
      repeat(info.biWidth)begin
        @(posedge clk);
        i_sop = (cols==0) && (raws==0);
        i_data = read_pixels[raws][cols];
        i_valid = 1;
        cols++;
      end
      raws++;
      cols = 0;
    end
    i_eop = 1;
    @(posedge clk);
    i_valid = 0;
    i_eop = 0;


    #200 Writer.save_file("./results/Sharpen.bmp");

    $finish;
  end


endmodule