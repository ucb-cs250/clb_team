module transmission_gate(input value, output out, input active);
    assign out = active ? value : 1'bz;
endmodule : transmission_gate
