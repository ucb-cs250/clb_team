module mux_predecoded #(
    parameter WIDTH=4, ADDR_W =$clog2(WIDTH)
) (
    input  [WIDTH-1:0] data,
    output out,
    input  [ADDR_W-1:0] addr
);

wire [WIDTH-1:0] select;

generate
genvar i;
for (i=0; i<WIDTH; i=i+1) begin
    if (i==0) 
        assign intermediate_use[i] = ~addr[1] & ~addr[0];
    else if (i==1) 
        assign intermediate_use[i] = ~addr[1] & addr[0];
    else if (i==2) 
        assign intermediate_use[i] = addr[1] & ~addr[0];
    else 
        assign intermediate_use[i] = addr[1] & addr[0];
    transmission_gate tg (data[i], out, select[i]);
end
endgenerate


endmodule : mux_predecoded
