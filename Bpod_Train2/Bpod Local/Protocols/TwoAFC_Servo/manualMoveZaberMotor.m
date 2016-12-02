function manualMoveZaberMotor(hObject, eventdata, motor_num)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents as double

global S motors_properties motors;

position = get(hObject,'String');

move_absolute(motors,str2num(position),str2num(motor_num));

