function outputZip = run_report_simulations
% RUN_REPORT_SIMULATIONS Export evidence from the uploaded Group 25 model.
% Open this folder in MATLAB R2025b and run: run_report_simulations
% Requires Simulink, Simscape, Simscape Electrical and Stateflow.
% Prepared from the user's model; NOT executed by ChatGPT (no MATLAB runtime).
% The original src/microgrid.slx is never saved or overwritten.

kit = fileparts(mfilename('fullpath'));
src = fullfile(kit,'src');
stamp = char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'));
outDir = fullfile(kit,['report_outputs_' stamp]);
mkdir(outDir);
oldFolder = pwd; oldPath = path;
restore = onCleanup(@() restoreEnvironment(oldFolder,oldPath)); %#ok<NASGU>
cd(src); addpath(src,'-begin'); addpath(fullfile(src,'icons'),'-begin');
diary(fullfile(outDir,'run_log.txt'));
fprintf('Group 25 report evidence export\nMATLAB: %s\n',version);
fprintf('Output folder: %s\n',outDir);
disp(ver);
mdl = 'microgrid_report_run';
try
    assert(~bdIsLoaded(mdl), ...
        'Close microgrid_report_run first, preserving any edits you want.');
    copyfile(fullfile(src,'microgrid.slx'),fullfile(outDir,[mdl '.slx']));
    copySource(src,outDir,kit);
    % Both uploaded model callbacks call this initialization script in base.
    evalin('base','microgrid_parameters');
    load_system(fullfile(outDir,[mdl '.slx']));
    closeCopy = onCleanup(@() close_system(mdl,0)); %#ok<NASGU>
    nl = char(10);
    pv = [mdl '/PV System']; urfc = [mdl '/URFC System'];
    tank = [urfc '/Tank'];
    currentBlock = [mdl '/Constant'];
    radiationBlock = [pv '/PS Constant1'];
    solverBlock = [mdl '/Solver' nl 'Configuration'];

    verifyUploadedModel(src,mdl,currentBlock,radiationBlock);
    set_param(mdl,'SignalLogging','on','SignalLoggingName','logsout', ...
        'ReturnWorkspaceOutputs','on','StartTime','0','StopTime','600');
    set_param(solverBlock,'UseLocalSolver','on','LocalSolverSampleTime','1');
    set_param([tank '/PS-Simulink' nl 'Converter'],'Unit','g/s');
    set_param([tank '/PS-Simulink' nl 'Converter1'],'Unit','g/s');
    set_param([pv '/PS-Simulink' nl 'Converter'],'Unit','W');

    logOutput([tank '/Integrator'],1,'H2_mass_g');
    logOutput([tank '/PS-Simulink' nl 'Converter1'],1,'H2_net_flow_gps');
    logOutput([pv '/PS-Simulink' nl 'Converter'],1,'PV_calculated_power_W');
    logOutput(currentBlock,1,'I_reference_A');
    for pair = {'Sensor EL','Sensors FC'}
        subsystem = [urfc '/' pair{1}];
        if strcmp(pair{1},'Sensor EL'), tag = 'EL'; else, tag = 'FC'; end
        set_param([subsystem '/PS-Simulink' nl 'Converter1'],'Unit','A');
        set_param([subsystem '/PS-Simulink' nl 'Converter2'],'Unit','V');
        logOutput([subsystem '/PS-Simulink' nl 'Converter1'],1,[tag '_stack_current_A']);
        logOutput([subsystem '/PS-Simulink' nl 'Converter2'],1,[tag '_stack_voltage_V']);
        logOutput([subsystem '/Product'],1,[tag '_stack_power_signed_W']);
    end

    % Ideal sensors in a COPY: series current at PV converter output,
    % and voltage across its positive/negative output terminals.
    % If a library version prevents instrumentation, baseline tests still run.
    measurementOK = false;
    save_system(mdl,fullfile(outDir,[mdl '.slx']));
    try
        addPVMeasurements(pv);
        set_param(mdl,'SimulationCommand','update');
        measurementOK = true;
        fprintf('PV output current and DC-bus voltage sensors added.\n');
    catch sensorError
        fprintf(2,'PV instrumentation failed; restoring original PV subsystem.\n%s\n', ...
            getReport(sensorError,'extended','hyperlinks','off'));
        writeText(fullfile(outDir,'PV_INSTRUMENTATION_ERROR.txt'), ...
            getReport(sensorError,'extended','hyperlinks','off'));
        % Discard every in-memory edit from the attempted sensor insertion.
        close_system(mdl,0);
        load_system(fullfile(outDir,[mdl '.slx']));
    end
    save_system(mdl,fullfile(outDir,[mdl '.slx']));
    exportDiagrams(mdl,outDir);

    cases = table({'EL_100A';'FC_200A';'OFF';'PV_1000';'PV_500'}, ...
        [100;-200;0;0;0],[1;1;1;1;0.5], ...
        'VariableNames',{'Case','Reference_A','NormalizedIrradiance'});
    cases.Success = false(height(cases),1);
    cases.FinalTime_s = nan(height(cases),1);
    cases.InitialMass_g = nan(height(cases),1);
    cases.FinalMass_g = nan(height(cases),1);
    cases.FittedSlope_gps = nan(height(cases),1);
    cases.IdealCommandSlope_gps = 2.01588*10/(2*96485)*cases.Reference_A;
    cases.TankLimitViolation = false(height(cases),1);
    cases.Error = repmat({''},height(cases),1);
    results = cell(height(cases),1);
    for k = 1:height(cases)
        name = cases.Case{k}; caseDir = fullfile(outDir,name); mkdir(caseDir);
        fprintf('\n[%d/%d] Running %s for 600 simulated seconds...\n',k,height(cases),name);
        try
            in = Simulink.SimulationInput(mdl);
            in = in.setBlockParameter(currentBlock,'Value',num2str(cases.Reference_A(k)));
            in = in.setBlockParameter(radiationBlock,'constant',num2str(cases.NormalizedIrradiance(k)));
            in = in.setModelParameter('StopTime','600','SignalLogging','on', ...
                'SignalLoggingName','logsout','ReturnWorkspaceOutputs','on');
            simulationOutput = sim(in);
            save(fullfile(caseDir,'simulation_output.mat'),'simulationOutput','-v7.3');
            logs = simulationOutput.logsout;
            exportCSVs(logs,caseDir);
            mass = series(logs,'H2_mass_g');
            assert(mass.Time(end) >= 599.9,'Simulation stopped before 600 s.');
            cases.FinalTime_s(k) = mass.Time(end);
            cases.InitialMass_g(k) = mass.Data(1);
            cases.FinalMass_g(k) = mass.Data(end);
            mask = mass.Time >= 60;
            assert(nnz(mask) >= 2,'Insufficient data after 60 s for a slope fit.');
            coeff = polyfit(mass.Time(mask),mass.Data(mask),1);
            cases.FittedSlope_gps(k) = coeff(1);
            cases.TankLimitViolation(k) = any(mass.Data < 200 | mass.Data > 1000);
            cases.Success(k) = true; results{k} = logs;
            exportCasePlots(logs,caseDir,name,measurementOK);
            fprintf('Final H2: %.6f g; fitted slope: %.8f g/s\n',mass.Data(end),coeff(1));
        catch ME
            cases.Error{k} = ME.message;
            writeText(fullfile(caseDir,'ERROR.txt'),getReport(ME,'extended','hyperlinks','off'));
            fprintf(2,'FAILED: %s\n%s\n',name,ME.message);
        end
        writetable(cases,fullfile(outDir,'run_summary.csv'));
    end
    exportReportPlots(results,outDir,measurementOK);
    writeText(fullfile(outDir,'RESULT_STATUS.txt'),sprintf([ ...
        '%d of %d cases have complete simulation data.\n' ...
        'PV bus instrumentation enabled: %d\n' ...
        'Graphs come from logged Simulink outputs. Ideal slopes in the CSV are theoretical checks.\n' ...
        'No 24-hour dispatch, optimal-control comparison or motor speed-control test was run.\n' ...
        'Grid support remains enabled; these plots do not prove islanded regulation.\n' ...
        'Tank bounds are checked after each run; this does not implement a tank-aware controller.\n'], ...
        sum(cases.Success),height(cases),measurementOK));
    fprintf('\nFinished: %d/%d cases have complete simulation data.\n',sum(cases.Success),height(cases));
catch ME
    writeText(fullfile(outDir,'SETUP_ERROR.txt'),getReport(ME,'extended','hyperlinks','off'));
    fprintf(2,'Setup stopped: %s\nSend the output ZIP for diagnosis.\n',ME.message);
end
diary off;
outputZip = [outDir '.zip'];
[parent,folder] = fileparts(outDir);
zip(outputZip,{folder},parent);
fprintf('\nUPLOAD THIS FILE:\n%s\n',outputZip);
end

function verifyUploadedModel(src,mdl,currentBlock,radiationBlock)
assert(isfile(fullfile(src,'urfc_electrolyzer.ssc')),'Electrolyzer source missing.');
el = regexprep(fileread(fullfile(src,'urfc_electrolyzer.ssc')),'\s','');
fc = regexprep(fileread(fullfile(src,'urfc_fuel_cell.ssc')),'\s','');
assert(contains(el,'h2==mmH2*N_cells*i/(n_electrons*F_constant)'), ...
    'Expected corrected electrolyzer hydrogen equation is missing.');
assert(contains(fc,'I=(h2_in*n_electrons*F_constant)/(mmH2*N_cells)/A_cell'), ...
    'Expected corrected fuel-cell conversion is missing.');
assert(contains(get_param([mdl '/URFC System/Gain'],'Gain'),'n_electrons'), ...
    'Fuel-cell flow Gain must include n_electrons.');
assert(contains(get_param([mdl '/URFC System/PS Subtract'],'ReferenceBlock'),'PS Subtract'), ...
    'Tank balance must subtract fuel-cell consumption.');
get_param(currentBlock,'Value'); get_param(radiationBlock,'constant');
assert(strcmp(get_param([mdl '/Subsystem'],'Commented'),'on'), ...
    'This runner expects the uploaded constant-irradiance configuration.');
assert(strcmp(get_param([mdl '/PV System'],'Commented'),'off'),'PV is disabled.');
end

function addPVMeasurements(pv)
nl = char(10);
converter = [pv '/Average-Value DC-DC' nl 'Converter'];
positive = [pv '/+']; negative = [pv '/-'];
pc = get_param(converter,'PortHandles');
pp = get_param(positive,'PortHandles'); pn = get_param(negative,'PortHandles');
assert(numel(pc.RConn)==2 && numel(pp.RConn)==1 && numel(pn.RConn)==1, ...
    'PV port layout differs from the uploaded model.');
% Move boundary ports to leave room for visible measurement blocks.
set_param(positive,'Position',[740 110 770 130]);
set_param(negative,'Position',[740 210 770 230]);
ib = [pv '/Report Current Sensor']; vb = [pv '/Report Voltage Sensor'];
ic = [pv '/Report I to Simulink']; vc = [pv '/Report V to Simulink'];
pb = [pv '/Report Delivered Power'];
add_block('fl_lib/Electrical/Electrical Sensors/Current Sensor',ib, ...
    'Position',[520 100 570 140],'Orientation','right');
add_block('fl_lib/Electrical/Electrical Sensors/Voltage Sensor',vb, ...
    'Position',[620 200 670 240],'Orientation','right');
add_block(['nesl_utility/PS-Simulink' nl 'Converter'],ic, ...
    'Position',[795 45 840 75],'Unit','A');
add_block(['nesl_utility/PS-Simulink' nl 'Converter'],vc, ...
    'Position',[795 280 840 310],'Unit','V');
add_block('simulink/Math Operations/Product',pb,'Position',[930 150 965 185]);
add_block('simulink/Sinks/Terminator',[pv '/Report Power Terminator'], ...
    'Position',[1040 155 1060 175]);
ip = get_param(ib,'PortHandles'); vp = get_param(vb,'PortHandles');
ipc = get_param(ic,'PortHandles'); vpc = get_param(vc,'PortHandles');
% Library sensor mapping (verified against uploaded source metadata):
% LConn(1)=electrical +; RConn(1)=physical-signal output; RConn(2)=electrical -.
assert(numel(ip.LConn)==1 && numel(ip.RConn)==2 && ...
    numel(vp.LConn)==1 && numel(vp.RConn)==2,'Unexpected sensor port layout.');
delete_line(pv,pc.RConn(1),pp.RConn(1));
add_line(pv,pc.RConn(1),ip.LConn(1),'autorouting','on');
add_line(pv,ip.RConn(2),pp.RConn(1),'autorouting','on');
add_line(pv,pp.RConn(1),vp.LConn(1),'autorouting','on');
add_line(pv,pn.RConn(1),vp.RConn(2),'autorouting','on');
add_line(pv,ip.RConn(1),ipc.LConn(1),'autorouting','on');
add_line(pv,vp.RConn(1),vpc.LConn(1),'autorouting','on');
add_line(pv,'Report I to Simulink/1','Report Delivered Power/1','autorouting','on');
add_line(pv,'Report V to Simulink/1','Report Delivered Power/2','autorouting','on');
add_line(pv,'Report Delivered Power/1','Report Power Terminator/1','autorouting','on');
logOutput(ic,1,'PV_delivered_current_A');
logOutput(vc,1,'DC_bus_voltage_V');
logOutput(pb,1,'PV_delivered_power_W');
end

function logOutput(block,index,name)
p = get_param(block,'PortHandles');
set_param(p.Outport(index),'DataLogging','on','DataLoggingNameMode','Custom', ...
    'DataLoggingName',name,'DataLoggingDecimateData','off','DataLoggingLimitDataPoints','off');
end

function exportDiagrams(mdl,outDir)
folder = fullfile(outDir,'diagrams'); mkdir(folder);
paths = {mdl,[mdl '/PV System'],[mdl '/URFC System'], ...
    [mdl '/URFC System/Tank'],[mdl '/Grid'],[mdl '/Consumer']};
names = {'Fig_3_2_Main_model','Fig_3_4_PV_measurement_circuit', ...
    'Fig_3_3_URFC_circuit','Tank_mass_balance','Grid_supply','Consumer_load'};
for k=1:numel(paths)
    try
        open_system(paths{k},'force');
        print(['-s' paths{k}],'-dpng','-r300',fullfile(folder,[names{k} '.png']));
    catch ME
        writeText(fullfile(folder,[names{k} '_ERROR.txt']),ME.message);
    end
end
% Stateflow is a chart, not a normal subsystem print target.
try
    rt = sfroot;
    chart = rt.find('-isa','Stateflow.Chart','Path',[mdl '/URFC System/Operation mode controler']);
    if isempty(chart), error('Stateflow chart was not resolved.'); end
    chart.view;
    sfprint([mdl '/URFC System/Operation mode controler'],'png', ...
        fullfile(folder,'Operation_mode_chart'));
catch ME
    writeText(fullfile(folder,'Operation_mode_chart_ERROR.txt'),ME.message);
end
end

function ts = series(logs,name)
element = logs.getElement(name); ts = element.Values;
assert(isa(ts,'timeseries'),'Expected scalar timeseries for %s.',name);
ts.Data = double(ts.Data(:)); ts.Time = double(ts.Time(:));
assert(numel(ts.Time)==numel(ts.Data) && numel(ts.Time)>1, ...
    'Missing or nonscalar trace: %s',name);
assert(all(isfinite(ts.Time)) && all(isfinite(ts.Data)),'Nonfinite trace: %s',name);
end

function exportCSVs(logs,folder)
for k=1:logs.numElements
    e = logs.getElement(k); ts = e.Values;
    if isa(ts,'timeseries') && numel(ts.Data)==numel(ts.Time)
        T = table(ts.Time(:),double(ts.Data(:)),'VariableNames',{'Time_s','Value'});
        writetable(T,fullfile(folder,[matlab.lang.makeValidName(e.Name) '.csv']));
    end
end
end

function exportCasePlots(logs,folder,name,measurementOK)
plotOne(logs,'H2_mass_g','Stored hydrogen mass (g)', ...
    ['Hydrogen inventory: ' strrep(name,'_',' ')],fullfile(folder,'Hydrogen_mass'));
plotOne(logs,'PV_calculated_power_W','Calculated PV power (W)', ...
    ['PV component output: ' strrep(name,'_',' ')],fullfile(folder,'PV_calculated_power'));
if measurementOK
    f = newFigure; tiledlayout(f,3,1);
    specs = {'DC_bus_voltage_V','DC-bus voltage (V)'; ...
        'PV_delivered_current_A','PV output current (A)'; ...
        'PV_delivered_power_W','Delivered PV power (W)'};
    for j=1:3
        nexttile; t = series(logs,specs{j,1});
        plot(t.Time,t.Data,'LineWidth',1.5); grid on;
        xlabel('Time (s)'); ylabel(specs{j,2});
    end
    sgtitle(['Measured PV delivery: ' strrep(name,'_',' ')]);
    saveFigure(f,fullfile(folder,'PV_measured_delivery'));
end
end

function exportReportPlots(results,folder,measurementOK)
specs = {'Fig_5_1_EL_hydrogen','Electrolyzer: +100 A'; ...
    'Fig_5_2_FC_hydrogen','Fuel cell: -200 A'; ...
    'Fig_5_3_OFF_hydrogen','OFF: 0 A'};
for k=1:3
    if ~isempty(results{k})
        plotOne(results{k},'H2_mass_g','Stored hydrogen mass (g)', ...
            specs{k,2},fullfile(folder,specs{k,1}));
    end
end
if ~isempty(results{4}) && ~isempty(results{5})
    f = newFigure; hold on;
    for k=[4 5]
        ts = series(results{k},'PV_calculated_power_W');
        plot(ts.Time,ts.Data,'LineWidth',1.6);
    end
    grid on; xlabel('Time (s)'); ylabel('Calculated PV power (W)');
    legend('1000 W/m^2','500 W/m^2','Location','best');
    title('PV component power at two irradiances');
    saveFigure(f,fullfile(folder,'Fig_5_4_PV_irradiance_comparison'));
    if measurementOK
        f = newFigure; tiledlayout(f,2,1);
        for j=1:2
            nexttile; hold on;
            if j==1, sig='PV_delivered_power_W'; yl='Delivered PV power (W)';
            else, sig='DC_bus_voltage_V'; yl='DC-bus voltage (V)'; end
            for k=[4 5]
                ts=series(results{k},sig); plot(ts.Time,ts.Data,'LineWidth',1.5);
            end
            xlabel('Time (s)'); ylabel(yl); grid on;
            legend('1000 W/m^2','500 W/m^2','Location','best');
        end
        sgtitle('Measured PV delivery and grid-supported DC bus');
        saveFigure(f,fullfile(folder,'Fig_5_5_PV_delivery_and_bus_voltage'));
    end
end
end

function plotOne(logs,sig,yl,ttl,file)
ts=series(logs,sig); f=newFigure;
plot(ts.Time,ts.Data,'LineWidth',1.6); grid on;
xlabel('Time (s)'); ylabel(yl); title(ttl,'Interpreter','none');
saveFigure(f,file);
end
function f = newFigure
f=figure('Visible','off','Color','w','Position',[100 100 1050 650]);
end
function saveFigure(f,file)
finish = onCleanup(@() close(f)); %#ok<NASGU>
exportgraphics(f,[file '.png'],'Resolution',300);
savefig(f,[file '.fig']);
end
function copySource(src,folder,kit)
code=fullfile(folder,'code'); mkdir(code);
for pattern={'*.m','*.ssc'}
    files=dir(fullfile(src,pattern{1}));
    for k=1:numel(files), copyfile(fullfile(src,files(k).name),code); end
end
copyfile(fullfile(kit,'run_report_simulations.m'),code);
copyfile(fullfile(kit,'README.txt'),folder);
end
function writeText(file,content)
fid=fopen(file,'w'); assert(fid>=0,'Cannot write %s',file);
finish=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s',content);
end
function restoreEnvironment(folder,oldPath)
diary off; cd(folder); path(oldPath);
end
