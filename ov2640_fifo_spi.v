module ov2640_fifo_spi(
    //test
    //output  FIFO_Empty,
    //output  FIFO_RdEn,
    //output  [7:0] FIFO_DataIn,
    //output  FIFO_WrEn,
    //sys
    input   sys_clk,        //8M时钟输入
    input   sys_rst_n,
    //cam interface
    input   cam_pclk,  //cmos 数据像素时钟
    input   cam_vsync,  //cmos 场同步信号
    input   cam_href,  //cmos 行同步信号
    input   [7:0] cam_data,  //cmos 数据  
    output  cam_rst_n,
    output  cam_pwdn,
    output  cam_scl,
    output  clk_24m,
    inout   cam_sda,
    //spi
    output  MOSI_MASTER_o,
    output  SS_N_MASTER_o,
    output  SCLK_MASTER_o,
    output  cmos_frame_vsync
    );

//parameter define
parameter  SLAVE_ADDR = 7'h30         ;  //OV2640的器件地址7'h30
parameter  BIT_CTRL   = 1'b0          ;  //OV2640的字节地址为8位  0:8位 1:16位
parameter  CLK_FREQ   = 24'd8_000_000;  //i2c_dri模块的驱动时钟频率 65MHz
parameter  I2C_FREQ   = 18'd250_000   ;  //I2C的SCL时钟频率,不超过400KHz
parameter  CMOS_H_PIXEL = 24'd1600    ;  //CMOS水平方向像素个数,用于设置SDRAM缓存大小
parameter  CMOS_V_PIXEL = 24'd1200    ;  //CMOS垂直方向像素个数,用于设置SDRAM缓存大小

wire                  i2c_exec        ;  //I2C触发执行信号
wire   [23:0]         i2c_data        ;  //I2C要配置的地址与数据(高8位地址,低8位数据)          
wire                  cam_init_done   ;  //摄像头初始化完成
wire                  i2c_done        ;  //I2C寄存器配置完成信号
wire                  i2c_dri_clk     ;  //I2C操作时钟

wire   [7:0]         cmos_frame_data;      //有效数据
wire                 cmos_frame_valid;     //数据有效使能信号
//wire                 cmos_frame_vsync;

assign  cam_rst_n = 1'b1;           //不对摄像头硬件复位,固定高电平
assign  cam_pwdn = 1'b0;            //电源休眠模式选择 0：正常模式 1：电源休眠模式

wire    clk_80m;
wire    clk_96m;

wire    spi_tx_en;
wire    [7:0] spi_data_in;
wire    spi_tx_done;

//wire    FIFO_Empty;
//wire    FIFO_RdEn;
wire    [7:0] FIFO_DataOut;

wire    FIFO_Full;
//wire    FIFO_WrEn;
wire    [7:0] FIFO_DataIn;


//PLL配置模块
Gowin_rPLL0 u_rPLL0(
    .clkout(clk_80m),
    .clkin(sys_clk)
    );

Gowin_rPLL1 u_rPLL1(
    .clkout(clk_96m),
    .clkoutd(clk_24m),
    .clkin(sys_clk)
    );

//fifo配置模块
fifo_sc_top u_fifo_sc(
    .Data(FIFO_DataIn), //input [7:0] Data
    .Clk(clk_80m), //input Clk
    .WrEn(FIFO_WrEn), //input WrEn
    .RdEn(FIFO_RdEn), //input RdEn
    .Reset(0), //input Reset
    .Q(FIFO_DataOut), //output [7:0] Q
    .Empty(FIFO_Empty), //output Empty
    .Full(FIFO_Full) //output Full
	);

//I2C驱动模块
i2c_dri
   #(
    .SLAVE_ADDR         (SLAVE_ADDR),       //参数传递
    .CLK_FREQ           (CLK_FREQ  ),              
    .I2C_FREQ           (I2C_FREQ  )                
    )
   u_i2c_dri(   
    .clk                (sys_clk   ),
    .rst_n              (sys_rst_n ),   
        
    .i2c_exec           (i2c_exec  ),   
    .bit_ctrl           (BIT_CTRL  ),   
    .i2c_rh_wl          (1'b0),             //固定为0，只用到了IIC驱动的写操作   
    .i2c_addr           (i2c_data[23:8]),
    .i2c_data_w         (i2c_data[7:0]),
    .i2c_data_r         (),   
    .i2c_done           (i2c_done  ),   
    .scl                (cam_scl   ),   
    .sda                (cam_sda   ),   
        
    .dri_clk            (i2c_dri_clk)       //I2C操作时钟
    );

//I2C配置模块
i2c_ov2640_cfg 
   #(
     .CMOS_H_PIXEL      (CMOS_H_PIXEL),
     .CMOS_V_PIXEL      (CMOS_V_PIXEL)
    )   
   u_i2c_cfg(
    .clk                (i2c_dri_clk),
    .rst_n              (sys_rst_n),
    .i2c_done           (i2c_done),
    .i2c_exec           (i2c_exec),
    .i2c_data           (i2c_data),
    .init_done          (cam_init_done)
    );

//CMOS图像数据采集模块
cmos_capture_data u_cmos_capture_data(
    .rst_n              (sys_rst_n & cam_init_done), 
        
    .cam_pclk           (cam_pclk),
    .cam_vsync          (cam_vsync),
    .cam_href           (cam_href),
    .cam_data           (cam_data),
    
    .cmos_frame_vsync   (cmos_frame_vsync),     //有效帧同步
    .cmos_frame_href    (),
    .cmos_frame_valid   (cmos_frame_valid),    //数据有效使能信号
    .cmos_frame_data    (cmos_frame_data)      //有效数据
    );

//SPI配置模块
spi_master u_spi_master(
    .I_clk(clk_80m)             , // 全局时钟
    .I_rst_n(1)                 , // 复位信号，低电平有效
    .I_rx_en()                  , // 读使能信号
    .I_tx_en(spi_tx_en)         , // 发送使能信号
    .I_data_in(spi_data_in)     , // 要发送的数据
    .O_data_out()               , // 接收到的数据
    .O_tx_done(spi_tx_done)     , // 发送一个字节完毕标志位
    .O_rx_done()                , // 接收一个字节完毕标志位
    // 四线标准SPI信号定义
    .I_spi_miso()               , // SPI串行输入，用来接收从机的数据
    .O_spi_sck(SCLK_MASTER_o)   , // SPI时钟
    .O_spi_cs(SS_N_MASTER_o)    , // SPI片选信号
    .O_spi_mosi(MOSI_MASTER_o)    // SPI输出，用来给从机发送数据          
    );

//写FIFO模块配置
fifo_write u_fifo_write(
    .clk                (clk_80m),
    .rst_n              (cam_init_done),
    .fifo_is_full       (FIFO_Full),
    .dataEn             (cmos_frame_valid),
    .datain             (cmos_frame_data),
    .dataout            (FIFO_DataIn),
    .fifo_write_en      (FIFO_WrEn)
    );

//读FIFO模块配置
fifo_read u_fifo_read(
    .clk                (clk_80m),
    .rst_n              (cam_init_done),
    .fifo_is_empty      (FIFO_Empty),
    .datain             (FIFO_DataOut),
    .fifo_read_en       (FIFO_RdEn),
    .spi_tx_done        (spi_tx_done),
    .dataout            (spi_data_in),
    .spi_tx_en          (spi_tx_en)
    );

endmodule