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
    assign select[i] = addr == i;
    transmission_gate tg (data[i], out, select[i]);
end
endgenerate


endmodule : mux_predecoded
