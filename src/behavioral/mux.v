module mux #(
    parameter WIDTH=4, ADDR_W=$clog2(WIDTH)
) (input [WIDTH-1:0] data, output out, input [ADDR_W-1:0] addr);

    assign out = data[addr];

endmodule: mux

