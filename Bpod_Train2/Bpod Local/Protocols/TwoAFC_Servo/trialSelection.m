function [next_trial] = trialSelection()

global BpodSystem
global S



switch S.GUI.TrialType
    
    case 1
        next_trial = 0;
    case 2
        if ~isempty(BpodSystem.Data.TrialTypes)
            
            Data = BpodSystem.Data;
            Outcomes = zeros(1,Data.nTrials);
            
            for x = 1:Data.nTrials
                if Data.TrialSettings(x).GUI.TrialType==2
                    try
                        if ~isnan(Data.RawEvents.Trial{x}.States.Reward(1))
                            Outcomes(x) = 1;    % correct
                        elseif ~isnan(Data.RawEvents.Trial{x}.States.ExtraITI(1))
                            Outcomes(x) = 0;    % error
                        elseif ~isnan(Data.RawEvents.Trial{x}.States.NoResponse(1))
                            Outcomes(x) = 2;    % no repsonse
                        else
                            Outcomes(x) = 3;    % others
                        end
                    catch
                        Outcomes(x) = 0; %if were using a different protocol without reward state.
                    end
                else
                    Outcomes(x) = 3;        % others
                end
            end
            
            
            MaxSame = S.GUI.MaxSame;
            NoTrialProb = S.GUI.RightTrialProb;
            switch S.GUI.Autolearn
                
                case 1  % Autolearn    

                    index_switch=find(Data.TrialTypes(1:Data.nTrials)~=Data.TrialTypes(Data.nTrials));
                    if length(index_switch) ==0
                        index_switch=0;
                    end
                    
                    if sum(Outcomes(index_switch(end)+1:Data.nTrials)==1) >= MaxSame
                        if Data.TrialTypes(Data.nTrials)==0, next_trial = 1; else next_trial = 0; end
                    else
                        next_trial = Data.TrialTypes(Data.nTrials);
                    end;
                    
                case {2, 3}  % 'antiBias' or off
                    
                    correct_R_history = (Outcomes==1 & Data.TrialTypes==0);
                    correct_L_history = (Outcomes==1 & Data.TrialTypes==1);
                    
                    incorrect_R_history = (Outcomes==0 & Data.TrialTypes==0);
                    incorrect_L_history = (Outcomes==0 & Data.TrialTypes==1);
                    
                    if  length(Outcomes) > 20  && S.GUI.Autolearn == 2 % realy antibias
                         percent_R_corr = sum(correct_R_history(end-19:end)) / (sum(correct_R_history(end-19:end))+sum(correct_L_history(end-19:end)) );
                         percent_L_incorr = sum(incorrect_L_history(end-19:end)) / (sum(incorrect_R_history(end-19:end))+sum(incorrect_L_history(end-19:end)) );
                         newNoTrialProb = percent_R_corr /2+percent_L_incorr /2;
                
                    else
                        newNoTrialProb = NoTrialProb; % too short or antibias is off
                    end
                    
                    if isnan (newNoTrialProb)
                        newNoTrialProb = NoTrialProb;
                    end
                    if MaxSame > Data.nTrials
                        if rand(1)<=newNoTrialProp
                            next_trial = 1;
                        else
                            next_trial = 0;
                        end
                        
                    else
                        
                        if all(Data.TrialTypes(Data.nTrials-MaxSame+1:Data.nTrials) == Data.TrialTypes(Data.nTrials))
                            if Data.TrialTypes(Data.nTrials)==1, next_trial = 0;
                            else next_trial = 1;
                            end;
                        else
                            % Haven't reached MaxSame limits yet, choose at random:
                            if rand(1)<=newNoTrialProb , next_trial = 1; else next_trial = 0; end;
                        end;
                    end
                    
                    
                    
                    
                    if(S.GUI.Max_incorrect_Left>=1)
                        max_inc_left=floor(S.GUI.Max_incorrect_Left);
                        min_cor_left=floor(S.GUI.Min_correct_Left);
                        temp_cor_left_str=repmat('0', 1, max_inc_left);
                        
                        if (length(correct_L_history)>10)
                            temp_correctL_history=int2str(correct_L_history(Data.TrialTypes==1));
                            temp_correctL_history=temp_correctL_history(1:3:end);
                            left_num=max(10, max_inc_left+min_cor_left);
                            if( (length(temp_correctL_history)> left_num)   )
                                index=strfind(temp_correctL_history(end-left_num+1:end),  temp_cor_left_str);
                                if( index )
                                    if( sum(temp_correctL_history(end-left_num+index(end)+max_inc_left-1:end)=='1')<min_cor_left )
                                        next_trial = 1;
                                    end
                                end
                            end
                        end
                    end
                    
                    if(S.GUI.Max_incorrect_Right>=1)
                        max_inc_right=floor(S.GUI.Max_incorrect_Right);
                        min_cor_right=floor(S.GUI.Min_correct_Right);
                        temp_cor_right_str=repmat('0', 1, max_inc_right);
                        
                        if (length(correct_R_history)>10)
                            temp_correctR_history=int2str(correct_R_history(Data.TrialTypes==0));
                            temp_correctR_history=temp_correctR_history(1:3:end);
                            right_num=max(10, max_inc_right+min_cor_right);
                            if( (length(temp_correctR_history)> right_num)   )
                                index=strfind(temp_correctR_history(end-right_num+1:end),  temp_cor_right_str);
                                if( index )
                                    if( sum(temp_correctR_history(end-right_num+index(end)+max_inc_right-1:end)=='1')<min_cor_right )
                                        next_trial = 0;
                                    end
                                end
                            end
                        end
                    end
                case 3
                    
                    
                    
                    

            end
            
        else
            next_trial = round(rand(1));
        end
        
end

