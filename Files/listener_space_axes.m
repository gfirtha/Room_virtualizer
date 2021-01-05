classdef listener_space_axes < handle
    %LISTENER_SPACE_AXES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        main_axes
        room
        receiver
        reverberant_source_figs
        binaural_source_points
    end
    
    methods
        function obj = listener_space_axes(fig)
            obj.main_axes = fig;
            grid(fig,'on')
            xlabel(fig, 'x -> [m]')
            ylabel(fig, 'y -> [m]')
            xlim(fig,[-10,10]);
            ylim(fig,[-10,10]);
        end
        
        function room = draw_room(obj, wall_vertices)
            for n = 1 : length(wall_vertices)
                room{n} = line(wall_vertices{n}(1,:), wall_vertices{n}(2,:),'Color','black','LineWidth',2);
            end
        end
        
        function receiver = draw_head(obj,pos,R)
            N = 20;
            fi = (0:2*pi/N:2*pi*(1-1/N));
            x_head = cos(fi)*R;
            y_head = sin(fi)*R;
            fi_nose =  [10 5   0    -5  -10 ];
            A_nose = R*[1  1.15 1.2 1.15   1 ];
            x_nose = cosd(linspace(fi_nose(1),fi_nose(end),N)).*interp1(fi_nose,A_nose,linspace(fi_nose(1),fi_nose(end),N),'spline');
            y_nose = sind(linspace(fi_nose(1),fi_nose(end),N)).*interp1(fi_nose,A_nose,linspace(fi_nose(1),fi_nose(end),N),'spline');
            fi_lear =  fliplr([18.5 18   16   0    -5   -15 ]+90);
            A_lear  = fliplr(R*[1  1.08 1.1 1.04  1.06   1 ]);
            x_lear = cosd(linspace(fi_lear(1),fi_lear(end),N)).*interp1(fi_lear,A_lear,linspace(fi_lear(1),fi_lear(end),N));
            y_lear = sind(linspace(fi_lear(1),fi_lear(end),N)).*interp1(fi_lear,A_lear,linspace(fi_lear(1),fi_lear(end),N));
            fi_rear =  -[18.5 18   16   0    -5   -15 ]-90;
            A_rear =  R*[1  1.08 1.1 1.04  1.06   1 ];
            x_rear = cosd(linspace(fi_rear(1),fi_rear(end),N)).*interp1(fi_rear,A_rear,linspace(fi_rear(1),fi_rear(end),N));
            y_rear = sind(linspace(fi_rear(1),fi_rear(end),N)).*interp1(fi_rear,A_rear,linspace(fi_rear(1),fi_rear(end),N));
            x_torso = cos(fi)*R*0.7-R/7;
            y_torso = sin(fi)*R*1.7;
            x_rec = [x_torso;x_head;x_lear;x_rear;x_nose]';
            y_rec = [y_torso;y_head;y_lear;y_rear;y_nose]';
            x_rec = x_rec - mean(mean(x_rec));
            y_rec = y_rec - mean(mean(y_rec));
            c = [37, 160, 217;
                77, 41, 14;
                255 206 180;
                255 206 180;
                255 206 180]/255;
            receiver = patch(obj.main_axes, x_rec+pos(1) ,y_rec + pos(2),[0;1;1;1;1]);
            set(receiver,'FaceVertexCData',c);
            receiver.UserData = struct( 'Label', 1,...
                'Origin', [ mean(receiver.Vertices(:,1)), mean(receiver.Vertices(:,2))  ],...
                'Orientation', 0 );
        end
        
        function loudspeaker = draw_loudspeaker(obj,pos,R,orientation,idx)
            x1 = [  -1.8  -1.8  -1  -1 ]'*R;
            y1 = [   -1    1   1   -1 ]'*R;
            x2 = [   -1 -1    0   0 ]'*R;
            y2 = [   -1    1  1.5 -1.5 ]'*R;
            x = [x1,x2];
            y = [y1,y2];
            x = x - mean(mean(x));
            y = y - mean(mean(y));
            
            c = [0.2 0.2 0.2;
                0.5 0.5 0.5];
            loudspeaker = patch(obj.main_axes, x + pos(1), y + pos(2),[0;1]);
            set(loudspeaker,'FaceVertexCData',c);
            loudspeaker.UserData = struct( 'Label', idx,...
                'Origin', [ mean(loudspeaker.Vertices(:,1)), mean(loudspeaker.Vertices(:,2))  ],...
                'Orientation', orientation );
            rotate(loudspeaker,[0 0 1], orientation,...
                [loudspeaker.UserData.Origin(1),loudspeaker.UserData.Origin(2),0]);
        end
        
        function reverberant_source_figs = draw_reverberant_source(obj,source_position,image_position,idx)
            N = 20;
            R = 180;
            A = 0.1;
            orientation = [0];
            x_source = A(1)*cosd(linspace(-R(1),R(1),N))';
            y_source = A(1)*sind(linspace(-R(1),R(1),N))';
            
            x_source = x_source - mean(mean(x_source));
            y_source = y_source - mean(mean(y_source));
            
            c_s = [255 0 0]/255;
            c_ms = [255 255 255]/255*0.5;
            reverberant_source_figs{1} = patch(obj.main_axes, x_source + source_position(1), y_source + source_position(2),[1]);
            set(reverberant_source_figs{1},'FaceVertexCData',c_s,'FaceLighting','gouraud');
            reverberant_source_figs{1}.UserData = struct( 'Label', idx,...
                'Origin', [ mean(reverberant_source_figs{1}.Vertices(:,1)), mean(reverberant_source_figs{1}.Vertices(:,2))  ],...
                'Orientation', orientation );
            
            for n = 1 : length(image_position)
                reverberant_source_figs{n+1} = patch(obj.main_axes, x_source + image_position{n}(1), y_source + image_position{n}(2),[1]);
                set(reverberant_source_figs{n+1},'FaceVertexCData',c_ms,'FaceLighting','gouraud');
                reverberant_source_figs{n+1}.UserData = struct( 'Label', [idx,n],...
                    'Origin', [ mean(reverberant_source_figs{n+1}.Vertices(:,1)), mean(reverberant_source_figs{n+1}.Vertices(:,2))  ],...
                    'Orientation', orientation );
            end
            
        end
        function obj = update_reverberant_source_pos(obj,idx, source_pos)
            for n = 2 : size(obj.reverberant_source_figs{idx},2)
                obj.reverberant_source_figs{idx}{n}.Vertices = bsxfun( @plus,...
                source_pos{n-1}'-mean(obj.reverberant_source_figs{idx}{n}.Vertices,1),...
                obj.reverberant_source_figs{idx}{n}.Vertices);
            end
        end
        
    end
end

