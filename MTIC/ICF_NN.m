%% Code Author: Ahmed Tashrif Kamal - tashrifahmed@gmail.com
% http://www.ee.ucr.edu/~akamal
% no permission necessary for non-commercial use
% Date: 4/27/2013

%% 
classdef ICF_NN < handle
    properties
        x;
        x_;
        J;
        J_;

        V;
        Vtemp;
        v;
        vtemp;
        u;
        U;
    end
    
    methods
        
        %% constructor
        function a = ICF_NN(Nc,Nt,p,T,eta,xa,Pinv)
            if (nargin > 0)
                a(Nc,Nt) = ICF_NN;
                for i=1:Nc
                    for j=1:Nt
                        a(i,j).x_= xa{j}(:,1) + eta{j};
                        a(i,j).J_ = Pinv;
                        
                        a(i,j).x = zeros(p,T);
                        a(i,j).J = zeros(p,p);
                        a(i,j).v = zeros(p,1);
                        a(i,j).V = zeros(p,p);
                        a(i,j).vtemp = zeros(p,1);
                        a(i,j).Vtemp = zeros(p,p);
                        a(i,j).u = zeros(p,1);
                        a(i,j).U = zeros(p,p);
                    end
                end
            end
        end %end constructor
        
        
        
        
        
        
        
        %% data association
        function dataAssociation(a,Nc,Nt,p,z,zCount,Rinv,H,FOV)
            for i=1:Nc
                if zCount(i)>0
                    dist = zeros(Nt,zCount(i));
                    for j =1:Nt
                        for n = 1:zCount(i)
                            dist(j,n) = norm(z{i}(:,n)-H*a(i,j).x_);
                        end
                    end
                    
                    [Matching,~] = Hungarian(dist);
                    for j = 1:Nt
                        a(i,j).u = zeros(p,1);
                        a(i,j).U = zeros(p,p);
                        for n = 1:zCount(i)
                            if Matching(j,n) == 1
                                %if pointInRect(z{i}(:,n),FOV(:,i)) % shouldn't it be pointInRect(H*a(i,j).x_,FOV(:,i))?
                                if pointInRect(H*a(i,j).x_,FOV(:,i))
                                    a(i,j).u = H'*Rinv*z{i}(:,n);
                                    a(i,j).U = H'*Rinv*H;
                                end
                                break;
                            end
                        end
                    end
                    
                    
                else
                    for j =1:Nt
                        a(i,j).u = zeros(p,1);
                        a(i,j).U = zeros(p,p);
                    end
                    
                    
                end
            end
            
        end
        
        %% prepData
        function prepData(a,Nc,Nt)
            for i=1:Nc
                for j=1:Nt
                    a(i,j).v = 1/Nc * a(i,j).J_ * a(i,j).x_ + a(i,j).u;
                    a(i,j).V = 1/Nc * a(i,j).J_ + a(i,j).U;
                end
            end
        end
        
        
        %% consensus
        function consensus(a,Nc,Nt,p,K,eps,E)
            for k=1:K
                for i=1:Nc
                    for j=1:Nt
                        a(i,j).vtemp = zeros(p,1);
                        a(i,j).Vtemp = zeros(p,p);
                        Delta = sum(E(i,:));
                        for i_=1:Nc
                            if E(i,i_)
                                a(i,j).vtemp = a(i,j).vtemp + a(i_,j).v;
                                a(i,j).Vtemp = a(i,j).Vtemp + a(i_,j).V;
                            end
                        end
                        a(i,j).vtemp =   (1-Delta*eps)*a(i,j).v  + eps*a(i,j).vtemp;
                        a(i,j).Vtemp =   (1-Delta*eps)*a(i,j).V  + eps*a(i,j).Vtemp;
                    end
                end
                
                for i=1:Nc
                    for j= 1:Nt
                        a(i,j).v = a(i,j).vtemp;
                        a(i,j).V = a(i,j).Vtemp;
                    end
                end
                
            end
            
        end
        
        %% Estimate
        function estimate(a,Nc,Nt,p,t,Phi,Q)
            for i=1:Nc
                for j=1:Nt
                    a(i,j).x(:,t) = a(i,j).V \ a(i,j).v;
                    a(i,j).J = Nc * a(i,j).V;
                    a(i,j).x_ = Phi * a(i,j).x(:,t);
                    a(i,j).J_ = eye(p,p)/ ( Phi / a(i,j).J * Phi' + Q );
                end
            end
        end
        
        
        
        
        
        
        
    end %methods
    
end