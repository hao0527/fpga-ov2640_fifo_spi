module fifo_read(
    input clk,
    input rst_n,

    input fifo_is_empty,
    input [7:0] datain,
    output reg fifo_read_en,

    input spi_tx_done,
    output reg [7:0] dataout,
    output reg spi_tx_en
);

reg [1:0] fifo_read_state;
reg [0:0] idle = 1;
reg [7:0] data = 0;
reg fifo_data_ready = 0;
reg spi_read_done = 0;

//收FIFO
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        fifo_read_en = 0;
        fifo_read_state = 0;
        data = 0;
    end

    else if(spi_read_done) begin
        fifo_data_ready = 0;
    end

    else
        case(fifo_read_state)
        2'd0:
            begin
                if(!fifo_is_empty && !fifo_data_ready) begin
                    fifo_read_en = 1;
                    fifo_read_state = 1;
                end
            end
        2'd1:
            begin
                data = datain;
                fifo_data_ready = 1;
                fifo_read_en = 0;
                fifo_read_state = 0;
            end
        endcase
end

//发SPI
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        dataout = 0;
        spi_tx_en = 0;
        spi_read_done = 0;
        idle = 1;
    end

    else if(spi_tx_done) begin
        idle = 1;
        spi_tx_en = 0;
    end

    else if(idle) begin
        if(fifo_data_ready) begin
            spi_read_done = 1;
            dataout[7:0] = data[7:0];
            spi_tx_en = 1;
            idle = 0;
        end
    end

    else if(spi_read_done) begin
        spi_read_done = 0;
    end
end

endmodule