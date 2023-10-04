classdef goniometerSA < handle_light
    %goniometer A class for controling the goniometer through the command window.
    %   By default, it uses the Newport motors and controllers.
    
    properties
        spectro %spectrometer object
        controller %controler object, such as an instance of ESP301 class (default)
    end
    
    methods
        function obj = goniometerSA(spectro,comport)
            %Initialise the goniometer. The first input argument is used to
            %pass a spectrometer object to the goniometer. The goniometer
            %will use this spectrometer object to measure spectre.
            %A comport can be specified using the second input argument but
            %this is optional.
            obj.spectro = spectro;
%             if (nargin == 1)
%                 obj.controller = ESP301();
%                 
%             else
%                 obj.controller = ESP301(comport);
                obj.controller = comport;
%             end
        end
        
        function scattering(obj,sampangles,detangles,waittime)
            %Performs a scattering measurement.
            %
            %obj.scattering(value, array) performs a scattering scan with
            %the angle of sample fixed.
            %
            %obj.scattering(array, value) performs a scattering scan with
            %the angle of detector fixed.
            %
            %Unless detangles or sampangles is 1 x 1 in size,
            %the second element onward of the shorter array will be ignored.
            if ~exist('waittime','var')
                 % third parameter does not exist, so default it to something
%                  waittime = 0.001;
                 waittime = obj.spectro.Integrationtimemin1000EditField.Value./1000000;
                 
            end
            
            slen = length(sampangles);
            dlen = length(detangles);
            if(slen<dlen)
                sampangles = ones(dlen,1)*sampangles(1);
            else
                detangles = ones(slen,1)*detangles(1);
            end
            obj.scan(sampangles,detangles,waittime);
        end
        
        function refscan
       % XX this is where the darkscan and bright scan must be called from
       % the specapp, to store the refscans, before the 
       Spectro.scatteringscanON = 1;
       % call scan, with dark saver OR bright saver
        end
%         function specular(obj,sampangles,waittime)            %%requiresm2
%             %Performes specular reflectionmeasurement.
%             %The angle of incidence is specified by the input argument.
%             %
%             %obj.specular(20:70)
%             %
%             if ~exist('waittime','var')
%                  % third parameter does not exist, so default it to something
%                  waittime = 0.001;
%             end
%             %will perform a specular reflection measurement from 20 degrees
%             %to 70 degrees incident angle with 1 degree step.
%             detangles = sampangles * 2;
%             obj.scan(sampangles,detangles,waittime);
%         end

%         function specular_transmission(obj,sampangles)            %%requiresm2
%             %Added by Axel Fouques to main goniometer.m file 19-11-19
%             %Performs transmission measurement in mirror configuration
%             %The angle of incidence is specified by the input argument.
%             %
%             %obj.specular(20:70)
%             %
%             %will perform a transmission measurement in mirror configuration from 20 degrees
%             %to 70 degrees incident angle with 1 degree step.
%             detangles = 180 + sampangles * 2;
%             obj.scan(sampangles,detangles);
%         end
        
        function scan(obj,sampangles,detangles,waittime)
            %Performs a scan with an arbitual set of angles.
            %This implementation should go to an abstract class in the future
            %so it can be reused in other classes.
            if ~exist('waittime','var')
                 % third parameter does not exist, so default it to something
%                  waittime = 0.001;
                 waittime = goni.spectro.Integrationtimemin1000EditField.Value./1000000;
            end
            
            len = length(detangles);
            if(len~=length(sampangles))
                throw(MException('goniometer:scan:badAngleLengths', ...
                    'detangle and sampangle must be vectors with same lengths.'));
            end
            %spectra = zeros(length(obj.spectro.wl),len);
%             Spectro = copy(obj.spectro);
            Spectro = obj.spectro;
            %Deepcopy to prevent accidental changes in the spectrometer settings.
            obj.prepareScan(Spectro,len);
            Spectro.multisave;
            for x = 1:len
                obj.controller.moveto(detangles(x));
%                 obj.controller.move(1,sampangles(x));
%                 obj.controller.wait(1);
%                 obj.controller.wait(2);
                pause(waittime+0.001);
%                 Spectro.read();
                Spectro.saver1(detangles(x));        % this public access in spectrapp works
%                 Spectro.saveWithMetadata( ... %    XXX                 'sampleangle',sampangles(x),...
%                     'detectorangle',detangles(x));
                pause(0.001); %I think there is a reason for this pause but cant remember why
            end
            Spectro.multisaveoff;
            Spectro.saver2; 
        end
        
%         function tiltrange(obj,cstangle, rangeangle, stepangle,waittime)            %%requiresm2
%             % measure with user-defined constant angle (cstangle) between sample and detector
%             %used for e.g. observing domain tilt in CNC films
%             if ~exist('waittime','var')
%                  % third parameter does not exist, so default it to something
%                  waittime = 0.001;
%             end
%             sampangles = cstangle/2-rangeangle:stepangle:cstangle/2+rangeangle;
%             detangles = cstangle*ones(length(sampangles),1);
%             obj.scan(sampangles,detangles,waittime);
%         end
        
%         function tiltrangepetri(obj,cstangle, rangeangle, stepangle)            %%requiresm2
%             % measure with user-defined constant angle (cstangle) between sample and detector
%             %used for e.g. observing domain tilt in CNC films
%             
%             sampangles = cstangle/2-rangeangle:stepangle:cstangle/2+rangeangle;
%             sampangles = sampangles-90;
%             detangles = cstangle*ones(length(sampangles),1);
%             obj.scan(sampangles,detangles);
%         end

%         function sample(obj,angle)            %%requiresm2
%             %Moves the sample motor to an absolute position.
%             %obj.sample(10)
%             %
%             %will move the sample motor to 10 degrees.
%             obj.controller.move(1,angle);
%         end
        
        function detector(obj,angle)
            %Moves the detector motor to an absolute position.
            %
            %obj.detector(10)
            %
            %will move the detector motor to 10 degrees.
            obj.controller.moveto(angle);
%             obj.controller.moveto(2,angle);

        end
        
%         function jogsample(obj,angle)            %%requiresm2
%             %Moves the sample motor by an ammount specified by the input argument.
%             %
%             %obj.detector(10)
%             %
%             %will move the sample motor by 10 degrees from the current position.
%             obj.controller.relative(1,angle);
%         end
        
        function jogdetector(obj,angle)
            %Moves the detector motor by an ammount specified by the input argument.
            %
            %obj.detector(10)
            %
            %will move the detector motor by 10 degrees from the current position.
            obj.controller.relative(2,angle);
        end
        
        function home(obj)
            %Homes both the sample and detector motor.
%             obj.homesample();            %%requiresm2
            obj.homedetector();
        end
        
%         function homesample(obj)            %%requiresm2
%             %Homes the sample motor.
%             obj.controller.home(1)
%             obj.controller.wait(1);
%             obj.sample(sampleoffset());
%             obj.controller.wait(1);
%             obj.controller.sethome(1,90);
%         end
        
        function homedetector(obj)
            %Homes the detector motor.
            obj.controller.home;%(2);
%             obj.controller.wait;%(2);
%             obj.controller.sethome(2,detectoroffset());
%             obj.controller.setsoftwarelimit(2,initiallimits());
%             obj.controller.onsoftwarelimit(2);
%             obj.controller.onhardwarelimit(2);
        end
        
        function unlock(obj)
            obj.controller.offhardwarelimit(2);
            obj.controller.onsoftwarelimit(2);
            obj.controller.setsoftwarelimit(2,novicelimits());
        end
            
    end
    
    methods (Hidden = true, Access = public) %change to private later
        
        function newScan = prepareScan(obj,Spectro,len)
            %pre-allocate space for performance
%             stopLive();

% this bit is about pre-setting the size and shape of the scan by measuring
% what the output looks like - it should be done! But may not be vital, and
% is easier than this, it can be found in assortedSpectrometer.m in the
% original

%             templateScanStruct = Spectro.getScanStruct('sampleangle',0,'detectorangle',0);
%             Spectro.prepareBuffer(len,templateScanStruct);
        end
        
        function scanStruct = append2Scan(obj,Spectro,scanStruct,num)
            %pre-allocate space for performance
            newScan = Spectro.getScanStruct;
            fnames=fieldnames(scanStruct);
            for ii=1:length(fnames)
                thisField=fnames{ii};
                thisData=newScan.(thisField);
                
                if ischar(thisData)
                    scanStruct.(thisField){num} = thisData;
                                   
                elseif iscolumn(thisData) && isnumeric(thisData)
                    scanStruct.(thisField)(:,num) = thisData;
                    
                elseif isnumeric(thisData)
%                    scanStruct.(thisField)(num,:) = thisData;
%                     scanStruct.(thisField)(:,num) = thisData;
                    
                else
                    error 'Unrecognized data type'
                end
            end
            %%%%%%%%%%%%%%
        end
        function closesa(obj)
            obj.spectro.closeSASA;
        end
        
    end
    
    methods (Hidden)
        function delete(obj)
            delete(obj.controller);%you have to explicitely call this line,
            %otherwise child objects are sometimes not destructed properly.
        end
    end
    methods% (Access = protected)
        function stoplive(obj)
            %Stops timer objects with name "live" in order to ensure secure
            %measurement. This implementation needs to be moved to the
            %avaSpec class in the future.
            timers = timerfind();
            for num = length(timers)
                if strcmp(timers(num).name,  'live')
                    stop(timers(num));
                end
            end
        end
        
    end
end
