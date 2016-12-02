global motors_properties motors;

motors_properties.type = '@ZaberTCD1000';
motors_properties.port = 'COM9';
% motors = ZaberTCD1000(motors_properties.port);
% close_and_cleanup(motors);
out = instrfind('Port','COM9');
for i=1:length(out),
    fclose(out(i));
end
motors = ZaberTCD1000(motors_properties.port);
serial_open(motors);

        