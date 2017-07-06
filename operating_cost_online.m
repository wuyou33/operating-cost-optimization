function [cvx_optval ] = operating_cost_online( )
%% global variable
global OPTIONS Parameter
objval = 0;

OPTIONS.Distance = 300;
OPTIONS.velocity = [17 0];
OPTIONS.N_e = 2;
OPTIONS.N_g = 2;
OPTIONS.N_t = 24;

OPTIONS.velocity_avg = OPTIONS.Distance/OPTIONS.N_t;
OPTIONS.P_pr_avg = (OPTIONS.velocity_avg).^3*2.2e-3;
OPTIONS.Pg_Max(1) = 8;
OPTIONS.Pg_Min(1) = 1;
OPTIONS.Pg_Max(2) = 4;
OPTIONS.Pg_Min(2) = 0.5;

OPTIONS.Ppr_Max = 12;
OPTIONS.Pb_Max(1) = 1;
OPTIONS.Pb_Min(1) = -1;
OPTIONS.E_Max(1) = 3;

OPTIONS.P_L = [2.7 0.9]; % P_Generater
OPTIONS.P_L_Scale = [0.5 0.6 0.8 0.78 0.82 0.6 0.4 0.35 0.28 0.3 0.4 0.5 0.4]; 

% the load demand without random feature
P_L_Scale_off = interp1(1:13,OPTIONS.P_L_Scale,1:0.5:13,'spline');
% the load demand with random feature
P_L_Scale_on = interp1(1:13,OPTIONS.P_L_Scale,1:0.5:13,'spline') + 0.1*rand(1, 25)-0.05;

OPTIONS.P_L_TIME_off = sum(OPTIONS.P_L.'* P_L_Scale_off(:,1:OPTIONS.N_t), 1);
OPTIONS.P_L_TIME_on  = sum(OPTIONS.P_L.'* P_L_Scale_on(:,1:OPTIONS.N_t), 1);

OPTIONS.Coupled_load(1, :) = 1 * OPTIONS.P_L_TIME_on/6;
OPTIONS.Coupled_load(2, :) = 1 * OPTIONS.P_L_TIME_on/6;
load_information = [OPTIONS.P_L_TIME_on; OPTIONS.P_L_TIME_on; OPTIONS.Coupled_load];

save('load_information');

OPTIONS.Delta_Load = OPTIONS.P_L_TIME_on - mean( OPTIONS.P_L_TIME_off );

% generator function parameters
Parameter.G(1,1:3) = [13.5 10 300];
Parameter.G(2,1:3) = [6 30 250];
Parameter.E(1,1:3) = [1 120 0];
Parameter.alpha = 0.5;
Parameter.C_ss = 100;
Parameter.R_G = 1;
Parameter.error = 1e-3;

lambda_delta = zeros(1,OPTIONS.N_t);
lambda_Pb = zeros(1,OPTIONS.N_t);
delta_g = ones(1,OPTIONS.N_t);
% Pb = OPTIONS.Pb_Max/2*ones(1,OPTIONS.N_t);

delta(1,1:OPTIONS.N_t ) = 1;
delta(2,1:OPTIONS.N_t ) = 1;

% operation_mode =3;
% Redundent_switch(1,1:2) = [0 1];
% cost = cost_optimization( delta, Redundent_switch, operation_mode );

%%  operation_mode:
% 0 (normal wo PPA ESMC) 
% 1 (normal w PPA wo ESMC) 
% 2 (normal wo PPA w ESMC) 
% 3 (normal w PPA w ESMC)

% 4 (Fault wo PPA ESMC) 
% 5 (Fault w PPA wo ESMC) 
% 6 (Fault wo PPA w ESMC) 
% 7 (Fault w PPA w ESMC)

%% fault optimal cost finding
% max_numb_lowpower = size(find(sort_data <=1),2);
max_searchbit(1:2) = [2 7]; 
for index_search = 1:1
%     for operation_mode =  0:3
%         Redundent_switch(1,1:2) = [0 1];
%         index_search
%         [optimal_cost(1,:), temp(1).delta] = single_optimal_finding(delta, Redundent_switch, operation_mode );
% 
%         optimal(operation_mode+1).delta = temp(1).delta;
%         optimal(operation_mode+1).objval = optimal_cost(1,1);
%         optimal(operation_mode+1).online_objval = optimal_cost(1,2);
%         
%         [cvx_optval, Pg, Pb, Ppr ] = cost_optimization(delta, [1 0], operation_mode );
%         operating_cost = sum(Parameter.G(1,1)* power(Pg(1:2,1:OPTIONS.N_t),2)  + Parameter.G(1,2)*Pg(1:2,1:OPTIONS.N_t) + Parameter.G(1,3)*ones(2,OPTIONS.N_t) ...
%                         + Parameter.E(1,1)* power(Pb(1:2,1:OPTIONS.N_t),2) + Parameter.E(1,2)* power(Pb(1:2,1:OPTIONS.N_t),1), 1);
%         startup_cost = delta(1,1:OPTIONS.N_t) - [0 delta(1,1:OPTIONS.N_t-1)];
%         operating_cost = operating_cost + Parameter.C_ss*(startup_cost>0);
%         
%         power_data = zeros(7,OPTIONS.N_t);
%         power_data(1:2,:) =  Pg;
%         power_data(3:4,:) =  Pb;
%         power_data(5,:) =    Ppr;
%         power_data(6,:) = OPTIONS.P_L_TIME_on(1,1:OPTIONS.N_t);
%         power_data(7,:) = operating_cost;
%         
% %         power_data(1:2,:) =  [Pg; Pb; Ppr; OPTIONS.P_L_TIME_on(1,1:OPTIONS.N_t); operating_cost];
%         
%         filename = ['on_power_data_',num2str(operation_mode),'.mat'];
%         save(filename,'power_data');
%     end

    for operation_mode =  4:7
        Redundent_switch(1,1:2) = [0 0];
        [optimal_cost(1,:), temp(1).delta] = single_optimal_finding(delta, Redundent_switch, operation_mode,max_searchbit(index_search) );
        Redundent_switch(1,1:2) = [0 1];
        [optimal_cost(2,:), temp(2).delta] = single_optimal_finding(delta, Redundent_switch, operation_mode,max_searchbit(index_search) );
        Redundent_switch(1,1:2) = [1 0];
        [optimal_cost(3,:), temp(3).delta] = single_optimal_finding(delta, Redundent_switch, operation_mode,max_searchbit(index_search) );
        Redundent_switch(1,1:2) = [1 1];
        [optimal_cost(4,:), temp(4).delta] = single_optimal_finding(delta, Redundent_switch, operation_mode,max_searchbit(index_search) );

        cvx_optval= min(optimal_cost(:,1));
        index_optimal = find(optimal_cost(:,1)==cvx_optval);
        optimal(operation_mode+1).delta = temp(index_optimal(1)).delta;
%         optimal(operation_mode+1).objval = cvx_optval;
        optimal(operation_mode+1).online_objval = optimal_cost(index_optimal(1),1);
        optimal(operation_mode+1).objval_01 = optimal_cost(2,1);
        optimal(operation_mode+1).Redundent_switch = index_optimal(1)-1;
        
        online_objval(1, operation_mode+1) = optimal(operation_mode+1).online_objval;
        [cvx_optval, Pg, Pb, Ppr ] = cost_optimization(optimal(operation_mode+1).delta, optimal(operation_mode+1).Redundent_switch, operation_mode );
%         operating_cost = sum(Parameter.G(1,1)* power(Pg(1:2,1:OPTIONS.N_t),2)  + Parameter.G(1,2)*Pg(1:2,1:OPTIONS.N_t) + Parameter.G(1,3)*ones(2,OPTIONS.N_t) ...
%                         + Parameter.E(1,1)* power(Pb(1:2,1:OPTIONS.N_t),2) + Parameter.E(1,2)* power(Pb(1:2,1:OPTIONS.N_t),1), 1);
%         startup_cost = delta(1,1:OPTIONS.N_t) - [0 delta(1,1:OPTIONS.N_t-1)];
%         operating_cost = operating_cost + Parameter.C_ss*(startup_cost>0);
        
        power_data = zeros(7,OPTIONS.N_t);
        power_data(1:2,:) =  Pg;
        power_data(3:4,:) =  Pb;
        power_data(5,:) =    Ppr;
        power_data(6,:) = OPTIONS.P_L_TIME_on(1,1:OPTIONS.N_t);
        power_data(7,:) = optimal(operation_mode+1).online_objval;
        
        filename = ['on_power_data_',num2str(operation_mode),'.mat'];
        save(filename,'power_data');
        
    end
%     if index_search ==1
%         optimal_1=optimal;
%         save('optimal_1');
%     else
%         optimal_2=optimal;
%         save('optimal_2');
%     end
    
    for index_mode = 1:1:8
        online_objval(1, index_mode) = optimal(index_mode).online_objval;
    end
    online_objval(2,:) = (online_objval -online_objval(1))*100/online_objval(1);
%     filename = ['on_objval_',num2str(operation_mode),'.mat'];
    save('online_objval');

end
end


function [optimal_cost, optimal_delta] = single_optimal_finding(delta, Redundent_switch, operation_mode, max_searchbit )
[a, PG ] = cost_optimization_off( delta, Redundent_switch, operation_mode );
if isempty(PG(1)) || PG(1)==inf
    optimal_cost = inf;
    optimal_delta = inf;
    return;
else
    [sort_data, sort_index] = sort(PG(2,:),'ascend');
end

optimal_cost =inf;
optimal_delta = 0;
if operation_mode>= 4
    for index = 2^max_searchbit-1:-1:1
        temp_index = index;
        for index_delta = max_searchbit:-1:1
            temp_index = mod(temp_index,2^index_delta);
            if temp_index == 0
               delta(2,sort_index(index_delta)) =0;
            end
        end
        temp_optimal_cost = cost_optimization(delta, Redundent_switch, operation_mode );
        if temp_optimal_cost <= optimal_cost
            optimal_cost = temp_optimal_cost;
            optimal_delta = delta;
        end
    end
else
    optimal_cost = cost_optimization(delta, Redundent_switch, operation_mode );
end

end

function [cvx_optval, Pg_total, Pb_total, Ppr_total ] = cost_optimization( delta, Redundent_switch, operation_mode )
global OPTIONS Parameter
%%
    Pg_total = zeros(2,OPTIONS.N_t);
    Pb_total = zeros(2,OPTIONS.N_t);
    E_total = zeros(2,OPTIONS.N_t);
    Ppr_total = zeros(1,OPTIONS.N_t);
%     Ppr_total = zeros(2,2);
    rest_velocity_avg = OPTIONS.Distance;
    
    for t_index = 1:OPTIONS.N_t
        
      if t_index>1
          if isnan(Pg_total(1,t_index-1) )
              Pg_total =inf;
              Pb_total =inf;
              Ppr_total =inf;
              cvx_optval =inf;
              return
          else
              Pg_bound(1,1) = Parameter.R_G + Pg_total(1,t_index-1);
              Pg_bound(1,2) =   -Parameter.R_G + Pg_total(1,t_index-1);
              Pg_bound(2,1) = Parameter.R_G + Pg_total(2,t_index-1);
              Pg_bound(2,2) =   -Parameter.R_G + Pg_total(2,t_index-1);
          end
      end

      if isempty( delta(1,t_index) ) || delta(1,t_index)==inf || isnan( delta(1,t_index) )
          return
      end
      
%     cvx_begin
        cvx_begin quiet 
            variable Ppr(1) nonnegative
            variable Pb(2)
            variable E(2) nonnegative
        %     variable delta(N_g,N_t) binary
            variable Pg(2) nonnegative
            minimize( sum(  sum(Parameter.G(1,1)* power(Pg(1:2,1),2)  + Parameter.G(1,2)*Pg(1:2,1) + Parameter.G(1,3)*[1; 1]...
                            + Parameter.E(1,1)* power(Pb(1:2,1),2) + Parameter.E(1,2)* power(Pb(1:2,1),1),2) ,1 ) )
            subject to
                % the range constraints of all the variables
                Pg(1,1) <= delta(1,t_index) * OPTIONS.Pg_Max(1)
                Pg(2,1) <= delta(2,t_index) * OPTIONS.Pg_Max(1)
        %         Pg(1,1) >= delta(1,1) * OPTIONS.Pg_Min(1)
        %         Pg(2,1) >= delta(2,1) * OPTIONS.Pg_Min(1)
                if t_index ==1
                elseif abs ( delta(1,t_index) -  delta(1,t_index-1) ) == 1
                    Pg(1,1) >= 0
                    Pg(2,1) >= 0
                else 
                    Pg(1,1) <= Pg_bound(1,1)
                    Pg(1,1) >= Pg_bound(1,2)
                    Pg(2,1) <= Pg_bound(2,1)
                    Pg(2,1) >= Pg_bound(2,2)
                end

                Ppr(1,1) <= OPTIONS.Ppr_Max
                Pb(1,1) <= OPTIONS.Pb_Max
                Pb(1,1) >= OPTIONS.Pb_Min
                Pb(2,1) <= OPTIONS.Pb_Max
                Pb(2,1) >= OPTIONS.Pb_Min

                E(1,1) <=  OPTIONS.E_Max
                E(1,1) >= 0
                E(2,1) <=  OPTIONS.E_Max 
                E(2,1) >= 0

                % ESM output power and the capacity constraints
                if t_index == 1
                    2 - Pb(1,1) == E(1,1)
                    2 - Pb(2,1) == E(2,1)
                else
                    E_total(1,t_index-1) - Pb(1) == E(1)
                    E_total(2,t_index-1) - Pb(2) == E(2)
                end

%                 sum((Ppr(1)./2.2e-3).^(1/3)) >= OPTIONS.Distance/OPTIONS.N_t

                % system power balance
                if operation_mode <= 3
                    if operation_mode ==0                    
                        Ppr(1,1) == OPTIONS.P_pr_avg;
                        Pb(1:2,1) == 0
                    elseif operation_mode ==1
                        ((Ppr(1)/2.2e-3).^(1/3)) >= ((rest_velocity_avg-OPTIONS.Delta_Load(t_index))/2.2e-3).^(1/3)          
                        Pb(1:2,1) == 0
                    elseif operation_mode ==2                    
                        Ppr(1,1) == OPTIONS.P_pr_avg;
                    else
                        ((Ppr(1)/2.2e-3).^(1/3)) >= ((rest_velocity_avg-OPTIONS.Delta_Load(t_index))/2.2e-3).^(1/3)
                    end

                    sum(OPTIONS.Coupled_load(:,t_index)) +  OPTIONS.P_L_TIME_on(1,t_index) + Ppr(1) == sum(Pg(1:2)) + sum(Pb(1:2))

                elseif operation_mode <= 7
                    if operation_mode ==4                    
                        Ppr(1,1) == OPTIONS.P_pr_avg;
                        Pb(1:2,1) == 0
                    elseif operation_mode ==5
                        ((Ppr(1)/2.2e-3).^(1/3)) >= ((rest_velocity_avg-OPTIONS.Delta_Load(t_index))/2.2e-3).^(1/3)                    
                        Pb(1:2,1) == 0
                    elseif operation_mode ==6
                        Ppr(1,1) == OPTIONS.P_pr_avg;
                    else
                        ((Ppr(1)/2.2e-3).^(1/3)) >= ((rest_velocity_avg-OPTIONS.Delta_Load(t_index))/2.2e-3).^(1/3)
                    end

                    if t_index <= 4
                        sum(OPTIONS.Coupled_load(:,t_index)) +  OPTIONS.P_L_TIME_on(1,t_index) + Ppr(1) == sum(Pg(1:2)) + sum(Pb(1:2))
                    else
                        Redundent_switch*OPTIONS.Coupled_load(:,t_index) +  Parameter.alpha * OPTIONS.P_L_TIME_on(1,t_index) + Ppr(1) == Pg(1) + Pb(1)
            %              Parameter.alpha * OPTIONS.P_L_TIME_on(1,t_index) + Ppr(1,t_index) == Pg(1,t_index) + Pb(1,t_index)
                        ~Redundent_switch*OPTIONS.Coupled_load(:,t_index) + (1-Parameter.alpha) * OPTIONS.P_L_TIME_on(1,t_index)  == Pg(2) + Pb(2)
                    end
                end
        cvx_end
        Pg_total(1:2,t_index) = Pg;
        Pb_total(1:2,t_index) = Pb;
        E_total(1:2,t_index) = E;
        Ppr_total(1,t_index) = Ppr;
        rest_distance = OPTIONS.Distance - (Ppr_total(1,t_index)/2.2e-3).^(1/3);
        rest_velocity_avg = rest_distance/(OPTIONS.N_t - t_index);
%         OPTIONS.P_pr_avg = (OPTIONS.velocity_avg).^3*2.2e-3;
    
%         (OPTIONS.velocity_avg)*;
    end
    
    y = size(find(delta(1:2,2:OPTIONS.N_t) - delta(1:2,1:OPTIONS.N_t-1)==1),2);
%     if operation_mode<=4
%         Pg_total(1,1:OPTIONS.N_t) = Pg_total(1,1:OPTIONS.N_t) + OPTIONS.P_L_TIME_on(1,1:OPTIONS.N_t) - OPTIONS.P_L_TIME_on(1,1:OPTIONS.N_t);
%     else
%         Pg_total(1,1:OPTIONS.N_t) = Pg_total(1,1:OPTIONS.N_t) + Parameter.alpha * (OPTIONS.P_L_TIME_on(1,1:OPTIONS.N_t) - OPTIONS.P_L_TIME_on(1,1:OPTIONS.N_t));
%         Pg_total(2,1:OPTIONS.N_t) = Pg_total(2,1:OPTIONS.N_t) + (1-Parameter.alpha) * (OPTIONS.P_L_TIME_on(1,1:OPTIONS.N_t) - OPTIONS.P_L_TIME_on(1,1:OPTIONS.N_t));
%     end
%     cvx_optval(2) =  sum(  sum(Parameter.G(1,1)* power(Pg_total(1:2,1:OPTIONS.N_t),2)  + Parameter.G(1,2)*Pg_total(1:2,1:OPTIONS.N_t) + Parameter.G(1,3)*ones(2,OPTIONS.N_t) ...
%                         + Parameter.E(1,1)* power(Pb_total(1:2,1:OPTIONS.N_t),2) + Parameter.E(1,2)* power(Pb_total(1:2,1:OPTIONS.N_t),1),2) ,1 );
    cvx_optval = cvx_optval + y*Parameter.C_ss(1);

end

function [cvx_optval, Pg, Pb, Ppr ] = cost_optimization_off( delta, Redundent_switch, operation_mode )
global OPTIONS Parameter
%%
% for index_sm = 1:20
    %% subproblem
%     cvx_begin
    cvx_begin quiet 
        variable Ppr(1,OPTIONS.N_t) nonnegative
        variable Pb(2,OPTIONS.N_t)
        variable E(2,OPTIONS.N_t) nonnegative
    %     variable delta(N_g,N_t) binary
        variable Pg(2,OPTIONS.N_t) nonnegative
        minimize( sum(  sum(Parameter.G(1,1)* power(Pg(1:2,1:OPTIONS.N_t),2)  + Parameter.G(1,2)*Pg(1:2,1:OPTIONS.N_t) + Parameter.G(1,3)*ones(2,OPTIONS.N_t) ...
                        + Parameter.E(1,1)* power(Pb(1:2,1:OPTIONS.N_t),2) + Parameter.E(1,2)* power(Pb(1:2,1:OPTIONS.N_t),1),2) ,1 ) )
        subject to
            % the range constraints of all the variables
            Pg(1,1:OPTIONS.N_t) <= delta(1,1:OPTIONS.N_t) * OPTIONS.Pg_Max(1)
            Pg(2,1:OPTIONS.N_t) <= delta(2,1:OPTIONS.N_t) * OPTIONS.Pg_Max(1)
    %         Pg(1,1:OPTIONS.N_t) >= delta(1,1:OPTIONS.N_t) * OPTIONS.Pg_Min(1)
    %         Pg(2,1:OPTIONS.N_t) >= delta(2,1:OPTIONS.N_t) * OPTIONS.Pg_Min(1)

            Pg(1,2:OPTIONS.N_t) -Pg(1,1:OPTIONS.N_t-1) <= Parameter.R_G
            Pg(1,2:OPTIONS.N_t) -Pg(1,1:OPTIONS.N_t-1) >= -Parameter.R_G
            Pg(2,2:OPTIONS.N_t) -Pg(2,1:OPTIONS.N_t-1) <= Parameter.R_G
            Pg(2,2:OPTIONS.N_t) -Pg(2,1:OPTIONS.N_t-1) >= -Parameter.R_G

            Ppr(1,1:OPTIONS.N_t) <= OPTIONS.Ppr_Max * ones(1,OPTIONS.N_t)
            Pb(1,1:OPTIONS.N_t) <= OPTIONS.Pb_Max * ones(1,OPTIONS.N_t)
            Pb(1,1:OPTIONS.N_t) >= OPTIONS.Pb_Min * ones(1,OPTIONS.N_t)
            Pb(2,1:OPTIONS.N_t) <= OPTIONS.Pb_Max * ones(1,OPTIONS.N_t)
            Pb(2,1:OPTIONS.N_t) >= OPTIONS.Pb_Min * ones(1,OPTIONS.N_t)

            E(1,1:OPTIONS.N_t) <=  OPTIONS.E_Max * ones(1,OPTIONS.N_t)
            E(1,1:OPTIONS.N_t) >= zeros(1,OPTIONS.N_t)
            E(2,1:OPTIONS.N_t) <=  OPTIONS.E_Max * ones(1,OPTIONS.N_t)
            E(2,1:OPTIONS.N_t) >= zeros(1,OPTIONS.N_t)

            % ESM output power and the capacity constraints
            2 - Pb(1,1) == E(1,1)
            2 - Pb(2,1) == E(2,1)
            for t_index = 1:OPTIONS.N_t-1
                E(1,t_index) - Pb(1,t_index+1) == E(1,t_index+1)
                E(2,t_index) - Pb(2,t_index+1) == E(2,t_index+1)
            end


            % system power balance
            if operation_mode <= 3
                if operation_mode ==0                    
                    Ppr(1,1:OPTIONS.N_t) == OPTIONS.P_pr_avg;
                    Pb(1:2,1:OPTIONS.N_t) == 0
                elseif operation_mode ==1
                    sum((Ppr(1:OPTIONS.N_t)./2.2e-3).^(1/3)) >= OPTIONS.Distance                    
                    Pb(1:2,1:OPTIONS.N_t) == 0
                elseif operation_mode ==2                    
                    Ppr(1,1:OPTIONS.N_t) == OPTIONS.P_pr_avg;
                else
                    sum((Ppr(1:OPTIONS.N_t)./2.2e-3).^(1/3)) >= OPTIONS.Distance
                end
                    
                for t_index = 1:OPTIONS.N_t
                    sum(OPTIONS.Coupled_load(:,t_index)) +  OPTIONS.P_L_TIME_off(1,t_index) + Ppr(1,t_index) == sum(Pg(1:2,t_index)) + sum(Pb(1:2,t_index))
                end
            elseif operation_mode <= 7
                if operation_mode ==4                    
                    Ppr(1,1:OPTIONS.N_t) == OPTIONS.P_pr_avg;
                    Pb(1:2,1:OPTIONS.N_t) == 0
                elseif operation_mode ==5
                    sum((Ppr(1:OPTIONS.N_t)./2.2e-3).^(1/3)) >= OPTIONS.Distance                    
                    Pb(1:2,1:OPTIONS.N_t) == 0
                elseif operation_mode ==6
                    Ppr(1,1:OPTIONS.N_t) == OPTIONS.P_pr_avg;
                else
                    sum((Ppr(1:OPTIONS.N_t)./2.2e-3).^(1/3)) >= OPTIONS.Distance
                    
                end
                
                for t_index = 1:4
                    sum(OPTIONS.Coupled_load(:,t_index)) +  OPTIONS.P_L_TIME_off(1,t_index) + Ppr(1,t_index) == sum(Pg(1:2,t_index)) + sum(Pb(1:2,t_index))
                end
                
                for t_index = 5:OPTIONS.N_t
                    Redundent_switch*OPTIONS.Coupled_load(:,t_index) +  Parameter.alpha * OPTIONS.P_L_TIME_off(1,t_index) + Ppr(1,t_index) == Pg(1,t_index) + Pb(1,t_index)
                    ~Redundent_switch*OPTIONS.Coupled_load(:,t_index) + (1-Parameter.alpha - 1/6) * OPTIONS.P_L_TIME_off(1,t_index)  == Pg(2,t_index) + Pb(2,t_index)
                end
            end
    cvx_end
    
    y = size(find(delta(1:2,2:OPTIONS.N_t) - delta(1:2,1:OPTIONS.N_t-1)==1),2);
    if operation_mode<=4
        Pg(1,1:OPTIONS.N_t) = Pg(1,1:OPTIONS.N_t) + OPTIONS.P_L_TIME_off(1,1:OPTIONS.N_t) - OPTIONS.P_L_TIME_on(1,1:OPTIONS.N_t);
    else
        Pg(1,1:OPTIONS.N_t) = Pg(1,1:OPTIONS.N_t) + Parameter.alpha * (OPTIONS.P_L_TIME_off(1,1:OPTIONS.N_t) - OPTIONS.P_L_TIME_on(1,1:OPTIONS.N_t));
        Pg(2,1:OPTIONS.N_t) = Pg(2,1:OPTIONS.N_t) + (1-Parameter.alpha -1/6) * (OPTIONS.P_L_TIME_off(1,1:OPTIONS.N_t) - OPTIONS.P_L_TIME_on(1,1:OPTIONS.N_t));
    end
    cvx_optval(2) =  sum(  sum(Parameter.G(1,1)* power(Pg(1:2,1:OPTIONS.N_t),2)  + Parameter.G(1,2)*Pg(1:2,1:OPTIONS.N_t) + Parameter.G(1,3)*ones(2,OPTIONS.N_t) ...
                        + Parameter.E(1,1)* power(Pb(1:2,1:OPTIONS.N_t),2) + Parameter.E(1,2)* power(Pb(1:2,1:OPTIONS.N_t),1),2) ,1 );
    cvx_optval = cvx_optval + y*Parameter.C_ss(1);

end
         