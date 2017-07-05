function master_problem(Pg, Pb, sub_delta, Ppr )
global delta OPTIONS Parameter

N_e = OPTIONS.N_e; 
N_g = OPTIONS.N_g; 
N_t = OPTIONS.N_t;
% alpha = Parameter.alpha;

Pg_Max(1:N_t) = 8;
Ppr_Max(1:N_t) = 12;
Pb_Max(1:N_t) = 2;
Pb_Min(1:N_t) = -2;
E_Max(1:N_t) = 2;
Pg_constant(1:N_t) = 1; 

Pb(1,1:N_t) = 0;
E(2,1:N_t) = 2;
C_ss = 100; 
   
delta = zeros(N_g,N_t);
delta(2,5:8) = 0;

%% MASTER PROBLEM OPTIMIZATION
for type_index = 1:(2^12-1)
    regression_delta(1);
    delta(1,1:N_t)
    
    number_of_startup_shutdown = sum(abs(delta(1:N_g,2:N_t) - delta(1:N_g,1:N_t-1)));   

    Pg(1,1:N_t) = delta(1,1:N_t).*Pg(1,1:N_t);
    Pg(2,1:N_t) = delta(2,1:N_t).*Pg(2,1:N_t);

    cvx_begin
        variable mu_B nonnegative
        variable Pb(2,N_t) nonnegative
    %     variable delta(N_g,N_t) binary
    %     variable Pg(1,N_t) nonnegative
        minimize( sum( Parameter.E(1,1)* power(Pb(1,1:N_t),1) + Parameter.E(1,1)* power(Pb(2,1:N_t),1) ) + sum( C_ss * number_of_startup_shutdown ) +  mu_B )
        subject to
            % the range constraints of all the variables + sum( C_ss * number_of_startup_shutdown ) +  mu
            Pb(1,1:N_t) <= Pb_Max(1:N_t)
            Pb(2,1:N_t) <= Pb_Max(1:N_t)
            Pb(1,1:N_t) >= Pb_Min(1:N_t)
            Pb(2,1:N_t) >= Pb_Min(1:N_t)
            E(1,1:N_t) <= E_Max(1:N_t)
            E(2,1:N_t) <= E_Max(1:N_t)

            % system power balance
            for t_index = 1:12
                Parameter.alpha * OPTIONS.P_L_TIME(1,t_index) + Ppr(t_index) == Pg(1,t_index) + Pb(1,t_index)
                (1 - Parameter.alpha) * OPTIONS.P_L_TIME(1,t_index) == Pg(2,t_index) + Pb(2,t_index)
            end

            % ESM output power and the capacity constraints        
            2 - Pb(1,1) == E(1,1)
            2 - Pb(2,1) == E(2,1)
            for t_index = 1:11
                E(1,t_index) - Pb(1,t_index+1) == E(1,t_index+1)
                E(2,t_index) - Pb(2,t_index+1) == E(2,t_index+1)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
            end
            mu_B >= sum(  Parameter.G(1,1)* power(Pg(1,1:N_t),2)  + Parameter.G(1,2)*Pg(1,1:N_t) + Parameter.G(1,3)*Pg_constant(1:N_t) ...
                        + Parameter.G(2,1)* power(Pg(2,1:N_t),2)  + Parameter.G(2,2)*Pg(2,1:N_t) + Parameter.G(2,3)*Pg_constant(1:N_t) ...
                        + Parameter.E(1,1)* power(Pb(1,1:N_t),2) + Parameter.E(1,1)* power(Pb(2,1:N_t),2) )  ...
                        + lambda_d( OPTIONS.Distance - sum((Ppr(1:N_t)/2.2e-3).^(1/3)) ) ...
                        + lambda_b1* ( Pg(1:t_index) + Pb(1:t_index) - alpha * P_L_TIME(1:t_index) - Ppr(1:t_index) ) ...
                        + lambda_b2 * ( Pg(2,1:t_index) + Pb(2,1:t_index) - (1-alpha) * P_L_TIME(1:t_index) )
    cvx_end

    % if isempty(solution) % If the problem is infeasible or you stopped early with no solution
    %     disp('intlinprog did not return a solution.')
    %     return % Stop the script because there is nothing to examine
    % end
    optimal_value(type_index) = cvx_optval;

end

LB = min(optimal_value);

%% FIGURE PLOT
figure
plot(Ppr,'linewidth',1.5);
hold on
plot(P_L_TIME(1,:),'linewidth',1.5);
hold on
% plot(Ppr(1,1:N_t)+P_L_TIME(1,1:N_t),'k','linewidth',2);
hold on
plot(Pb(1,1:N_t),'linewidth',1.5);
hold on
plot(Pb(2,1:N_t),'linewidth',1.5);
hold on
plot(Pg(1,1:N_t),'linewidth',1.5);
hold on
plot(Pg(2,1:N_t),'linewidth',1.5);
hold on
% plot(Pb(1,1:N_t)+Pg(1,1:N_t),'r');
% ylim([0 5]);

legend('P_{PR}','P_{L}','P_{b_1}','P_{b_2}','P_{g_1}','P_{g_2}');
% legend('P_{PR}','P_{L}','P_{B1}','P_{B2}','P_G');
end

function regression_delta(index)
global delta
    if delta(1,index) == 1
        delta(1,index) = 0;
        regression_delta(index+1);
    elseif delta(1,index) == 0
        delta(1,index) = 1;
    end
end