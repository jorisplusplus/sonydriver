module drive(iSysclk, iWREN, iImage, iAddress, iBrightness, iClkFrame, oUC, oUP, oSDO);

input iSysclk;
input iWREN;
input [29:0] iImage;
input [12:0] iAddress;
input [3:0] iBrightness;

input iClkFrame;
output reg oUC = 0;
output oUP;
output [1:0] oSDO;

reg [29:0] imagebuf [8191:0];
reg [18:0] refreshcounter = 0;
reg [3:0] decimator = 0;
reg [7:0] address;
reg update;

reg [9:0] SDO0_buf, SDO1_buf;
reg [5:0] transmission_state;
reg [12:0] readaddress;
reg [29:0] readval;
reg [29:0] pixel0, pixel1;
reg [2:0] pixelpos;

wire [3:0] transpos;
wire [3:0] transpos_delay;

assign transpos = 9-decimator-(oUC ? 0 : 5);
assign transpos_delay = (transpos == 9) ? 0 : transpos + 1;

assign oSDO[0] = SDO0_buf[transpos];
assign oSDO[1] = SDO1_buf[transpos_delay];

integer i;
initial begin
for(i = 0; i<8192; i=i+1) begin
    imagebuf[i] = {i[9:0], i[9:0], i[9:0]};
end
end

always @ (posedge iSysclk) 
begin
    if(iWREN)
    begin
        imagebuf[iAddress] <= iImage;
    end
end

always @ (posedge iClkFrame)
begin
    readval <= imagebuf[readaddress];
end

always @ (posedge iClkFrame)
begin
    if(decimator != 4)
    begin
       decimator <= decimator + 1; 
    end
    else
    begin
        decimator <= 0;
        oUC <= ~oUC;
        if(oUC == 0)
        begin
           if(refreshcounter != 38580)
           begin
               refreshcounter <= refreshcounter + 1;
           end          
           else
            begin
               update <= 1;
               address <= 0;
               SDO0_buf <= 0;
               SDO1_buf <= 0;
               refreshcounter <= 0;
               transmission_state <= 0;
           end 
        end
    end
    
    if(update)
    begin
        if(transmission_state == 0)
        begin
            if(transpos_delay == 0)
                transmission_state <= 1;
        end
        else if(transmission_state == 1)
        begin
            pixelpos <= 0;
            if(transpos == 0)
                SDO0_buf <= {0, 0, iBrightness};
            else if(transpos_delay == 0)
            begin
                SDO1_buf <= {0, 0, iBrightness};
                transmission_state <= 2;
            end
        end
        else if(transmission_state == 51)
        begin
            if(transpos == 0)
            begin
                if(address != 239)
                begin
                    address <= address + 1;
                    SDO0_buf <= address + 1;
                    SDO1_buf <= address + 1;
                    transmission_state <= 0;
                end
                else
                begin
                    update <= 0;
                    SDO0_buf <= 0;
                    SDO1_buf <= 0;
                end
            end
        end
        else if(transmission_state % 3 == 2) 
        begin
            if(transpos == 2)
                readaddress <= {address, 0, pixelpos};
            else if(transpos_delay == 2)
                readaddress <= {address, 1, pixelpos};
            if(transpos == 0)
            begin
                SDO0_buf <= readval[29:20];
                pixel0 <= readval;
            end
            else if(transpos_delay == 0)
            begin
                SDO1_buf <= readval[29:20];
                pixel1 <= readval;
                transmission_state <= transmission_state + 1;
            end        
        end
        else if(transmission_state % 3 == 0) 
        begin
            if(transpos == 0)
                SDO0_buf <= pixel0[19:10];
            else if(transpos_delay == 0)
            begin
                SDO1_buf <= pixel1[19:10];
                transmission_state <= transmission_state + 1;
            end      
        end
        else if(transmission_state % 3 == 1) 
        begin
            if(transpos == 0)
                SDO0_buf <= pixel0[9:0];
            else if(transpos_delay == 0)
            begin
                SDO1_buf <= pixel1[9:0];
                transmission_state <= transmission_state + 1;
                pixelpos <= pixelpos + 1;
            end        
        end
    end
end
endmodule
