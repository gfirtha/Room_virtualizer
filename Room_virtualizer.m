function varargout = Room_virtualizer(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Room_virtualizer_OpeningFcn, ...
                   'gui_OutputFcn',  @Room_virtualizer_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end
if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end

% --- Executes just before Room_virtualizer is made visible.
function Room_virtualizer_OpeningFcn(hObject, eventdata, handles, varargin)
addpath(genpath('Samples'))
addpath(genpath('MS_tools'))
addpath(genpath('HRTF_tools'))
addpath(genpath('Files'));
addpath(genpath('room_models'));
SOFAstart;
%hrtf_sofa = SOFAload('FABIAN_HRIR_measured_HATO_0.sofa');
%hrtf_sofa = SOFAload('Fabian_corrected.sofa');

hrtf_sofa = SOFAload('BuK_ED_corr.sofa');
load room_model.mat

N_ssd = 45;
if length(varargin) == 0
    input_file = 'gitL.wav';
else
    input_file = varargin{1};
end
handles.sound_scene_setup = struct(  ...
    'Input_file',               input_file,...
    'Block_size',               1024*2, ...
    'HRTF',                     hrtf_sofa, ...
    'Volume',                   0.5,...
    'Room_Vertices',            vertices,...
    'Wall_vertices',            walls,...
    'Mirror_source_order',      4,...
    'Binaural_source_type',     struct('Shape','point_source','R',8.88/N_ssd/4),...
    'renderer_setup',           struct('R',mean(hrtf_sofa.SourcePosition(:,3)),'N',N_ssd,'Antialiasing','on') );

 handles.sound_scene_setup.Input_stream = dsp.AudioFileReader(handles.sound_scene_setup.Input_file,...
     'SamplesPerFrame',handles.sound_scene_setup.Block_size,'PlayCount',10);
handles.sound_scene_gui = listener_space_axes(handles.axes1);
handles.sound_scene = sound_scene(handles.sound_scene_gui,handles.sound_scene_setup);
handles.output = hObject;
guidata(hObject, handles); 


% --- Outputs from this function are returned to the command line.
function varargout = Room_virtualizer_OutputFcn(hObject, eventdata, handles) 
warning('off','all')
varargout{1} = handles.output;

% --- Executes on button press in play_btn.
function play_btn_Callback(hObject, eventdata, handles)
handles.stop_now = 0;
deviceWriter = audioDeviceWriter('SampleRate',handles.sound_scene_setup.Input_stream.SampleRate);
guidata(hObject,handles);
%elapsed_time = 0;
%i = 1;
while (~isDone(handles.sound_scene_setup.Input_stream))&&(~handles.stop_now)
%    tic
    output = handles.sound_scene.binauralize_sound_scene(handles.sound_scene_setup.Volume*...
        handles.sound_scene_setup.Input_stream());
%    elapsed_time(i) = toc;
    deviceWriter(output);
    drawnow limitrate
    handles = guidata(hObject);
    %i = i + 1;
    % mean(elapsed_time)
end
release(deviceWriter)
release(handles.sound_scene_setup.Input_stream)

% --- Executes on button press in load_file_btn.
function load_file_btn_Callback(hObject, eventdata, handles)
[file,path] = uigetfile('*.wav;*.mp3;*.aac;*.ac3');
handles.sound_scene_setup.Input_file = strcat(path,file);
handles.sound_scene_setup.Input_stream = dsp.AudioFileReader(handles.sound_scene_setup.Input_file,...
    'SamplesPerFrame',handles.sound_scene_setup.Block_size);
handles.sound_scene.delete(handles.sound_scene_gui);
handles.sound_scene = sound_scene(handles.sound_scene_gui,handles.sound_scene_setup);
guidata(hObject,handles);

% --- Executes on slider movement.
function Volume_Callback(hObject, eventdata, handles)
handles.sound_scene_setup.Volume = get(hObject,'Value');
guidata(hObject,handles)

function Volume_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function stop_btn_Callback(hObject, eventdata, handles)
handles.stop_now = 1;
guidata(hObject, handles);

% --- Executes on button press in Zoom_in.
function Zoom_in_Callback(hObject, eventdata, handles)
% hObject    handle to Zoom_in (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.sound_scene_gui.main_axes.XLim=1/1.5*handles.sound_scene_gui.main_axes.XLim;
handles.sound_scene_gui.main_axes.YLim=1/1.5*handles.sound_scene_gui.main_axes.YLim;


% --- Executes on button press in Zoom_out.
function Zoom_out_Callback(hObject, eventdata, handles)
% hObject    handle to Zoom_out (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.sound_scene_gui.main_axes.XLim=1.5*handles.sound_scene_gui.main_axes.XLim;
handles.sound_scene_gui.main_axes.YLim=1.5*handles.sound_scene_gui.main_axes.YLim;
