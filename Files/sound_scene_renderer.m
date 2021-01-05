classdef sound_scene_renderer < handle
    %RENDERER Summary of this class goes here
    %   Detailed explanation goes here
    % TODO: make input, rendeder out and binauarl buses
    % and "wire" them up
    properties
        reverberant_renderer
        binaural_renderer
        directivity_tables
    end
    
    methods
        function obj = sound_scene_renderer(reverberant_sources,binaural_sources,receiver, setup)
            N_fft = 2^nextpow2( min(setup.Block_size + size(setup.HRTF.Data.IR,3), 2*setup.Block_size) - 1 );

            for n = 1 : length(reverberant_sources)
                obj.reverberant_renderer{n} = reverberant_renderer(reverberant_sources{n}, binaural_sources, setup.Input_stream.SampleRate, setup.renderer_setup.Antialiasing);
            end
            for n = 1 : length(binaural_sources)
                obj.binaural_renderer{n} = binaural_renderer(binaural_sources{n}, ...
                    receiver,directivity_table(binaural_sources{1}.source_type, N_fft, setup.Input_stream.SampleRate));
            end
        end
        
        function update_reverberant_renderers(obj, idx)
            obj.reverberant_renderer{idx}.update_renderer;
        end
        
        % When receiver moved:
        function update_binaural_renderers(obj, idx, type)
            switch type
                case 'receiver_moved'
                    obj.binaural_renderer{idx}.update_hrtf;
                    obj.binaural_renderer{idx}.update_directivity;
                case 'receiver_rotated'
                    obj.binaural_renderer{idx}.update_hrtf;
                case 'source_moved'
                    obj.binaural_renderer{idx}.update_hrtf;
                    obj.binaural_renderer{idx}.update_directivity;
                case 'source_rotated'
                    obj.binaural_renderer{idx}.update_directivity;
            end
        end
        
        function output = render(obj, input)
            %% Sound field synthesis job
            reverberant_output = 0;
            for m = 1 : length(obj.reverberant_renderer)
                obj.reverberant_renderer{m}.reverberant_source.source_signal.set_signal(input(:,m));
                obj.reverberant_renderer{m}.render;
                
                reverberant_output = reverberant_output + cell2mat(cellfun( @(x) x.time_series,...
                    obj.reverberant_renderer{m}.output_signal , 'UniformOutput', false));
            end
            output_signal = signal;
            for n = 1 : length(obj.binaural_renderer)
                obj.binaural_renderer{n}.binaural_source.source_signal.set_signal(reverberant_output(:,n));
                obj.binaural_renderer{n}.render;
                output_signal.add_spectra(obj.binaural_renderer{n}.output_signal);
            end
            output = output_signal.get_signal;
        end
        
    end
end