classdef sound_scene < handle
    %SOUND_SCENE Summary of this class goes here
    %   Should contain description for the objects, present in the sound
    %   scene and interfaces positions with the gui
    
    properties
        room
        reverberant_sources
        binaural_sources % sources to be binauralized by binaural method
        receiver
        environment
        scene_renderer
    end
    
    methods
        function obj = sound_scene(gui, setup)
            obj.environment = environment;
            % Create room
            obj.create_room(setup, gui);
            % Create reverberant sound source
            source_pos = get_default_layout(setup.Input_stream.info.NumChannels, 1)';
            create_reverberant_source(obj, 1, source_pos, [-1;0], gui, setup.Mirror_source_order);
            obj.reverberant_sources{1}.set_input(zeros(setup.Block_size,1),setup.Input_stream.SampleRate);
            % Create receiver
            obj.create_receiver(gui);
            
            pos_ssd = get_default_layout(setup.renderer_setup.N,setup.renderer_setup.R);
            for n = 1 : setup.renderer_setup.N
                obj.create_binaural_source( pos_ssd(n,:),-pos_ssd(n,:)/norm(pos_ssd(n,:)), gui, setup.HRTF, setup.Binaural_source_type);
                obj.binaural_sources{n}.set_input(zeros(setup.Block_size,1),setup.Input_stream.SampleRate);
            end
            obj.scene_renderer = sound_scene_renderer(obj.reverberant_sources,obj.binaural_sources,obj.receiver, setup);
            
        end
        
        function obj = create_room(obj, setup, gui)
            obj.room = room(setup.Room_Vertices,setup.Wall_vertices);
            gui.room = gui.draw_room(cellfun( @(x) x.vertices, obj.room.walls,'UniformOutput',false));
        end
        
        function obj = create_reverberant_source(obj, idx, position, orientation, gui, N)
            idx = length(obj.reverberant_sources) + 1;
            obj.reverberant_sources{idx} = reverberant_source(idx, position, orientation, obj.room, N);
            
            gui.reverberant_source_figs{idx} = gui.draw_reverberant_source(...
                obj.reverberant_sources{idx}.position,...
                cellfun( @(x) x.position, obj.reverberant_sources{idx}.image_sources,'UniformOutput',false ),idx);
            
            draggable(gui.reverberant_source_figs{idx}{1},@update_rev_source_position, @update_rev_source_orientation);
            function update_rev_source_position(reverberant_source)
                
                obj.reverberant_sources{reverberant_source.UserData.Label}.position =...
                    (gui.reverberant_source_figs{reverberant_source.UserData.Label}{1}.UserData.Origin)';
                obj.room.update_mirror_source_positions( obj.reverberant_sources{reverberant_source.UserData.Label} );
                gui.update_reverberant_source_pos(reverberant_source.UserData.Label, cellfun( @(x) x.position, obj.reverberant_sources{reverberant_source.UserData.Label}.image_sources, 'UniformOutput',false));
                obj.scene_renderer.update_reverberant_renderers(reverberant_source.UserData.Label);
            end
            function update_rev_source_orientation(reverberant_source)
                disp('Rotating the reverberant source is not yet supported');
            end
        end
        
        
        function obj = create_receiver(obj, gui)
            default_rec_pos = [0,0];
            default_rec_orient = [1,0];
            R = 0.15;
            obj.receiver = receiver(default_rec_pos,default_rec_orient);
            gui.receiver = gui.draw_head(default_rec_pos,R);
            draggable(gui.receiver,@update_receiver_position, @update_receiver_orientation);
            function update_receiver_position(receiver)
                % When receiver is moved:
                % - amount of movement is calculated
                dx = gui.receiver.UserData.Origin - obj.receiver.position;
                % - receiver position is updated
                obj.receiver.position = gui.receiver.UserData.Origin;
                % - and each virtual loudspeaker is translated as well
                for n = 1 : length(gui.binaural_source_points)
                    gui.binaural_source_points{n}.Vertices = ...
                        bsxfun(@plus, gui.binaural_source_points{n}.Vertices , [dx,0]);
                    obj.binaural_sources{n}.position = obj.binaural_sources{n}.position +dx;
                end
                % - finally the loudspeaker driving functions are updated
                for n = 1 : length(obj.reverberant_sources)
                    obj.scene_renderer.update_reverberant_renderers(n);
                end
            end
            function update_receiver_orientation(receiver)
                obj.receiver.orientation = [cosd(gui.receiver.UserData.Orientation),...
                    sind(gui.receiver.UserData.Orientation)];
                for n = 1 : length(obj.scene_renderer.binaural_renderer)
                    obj.scene_renderer.update_binaural_renderers(n, 'receiver_rotated' );
                end
            end
        end
        
        function obj = delete_receiver(obj, gui)
            obj.receiver = {};
            delete(gui.receiver);
        end
        
        function obj = create_binaural_source(obj, position, orientation, gui, hrtf, type)
            idx = length(obj.binaural_sources) + 1;
            obj.binaural_sources{idx} = binaural_source(idx, position, orientation, hrtf, type);
            gui.binaural_source_points{idx} = ...
                gui.draw_loudspeaker(position,type.R(1),cart2pol(orientation(1),orientation(2))*180/pi,idx);
        end
        
        function obj = delete_binaural_source(obj, bin_source_idx, gui)
            obj.binaural_sources(bin_source_idx) = [];
            delete(gui.binaural_source_points{bin_source_idx});
        end
        
        function obj = delete(obj,gui)
            obj.delete_receiver(gui);
            N = length(obj.virtual_sources);
            for n = 1 : N
                obj.delete_virtual_source(N-n+1,gui);
            end
            N = length(obj.binaural_sources);
            for n = 1 : N
                obj.delete_binaural_source(N-n+1,gui);
            end
            clear obj
        end
        
        function output = binauralize_sound_scene(obj,input)
            output = obj.scene_renderer.render(input);
        end
    end
end