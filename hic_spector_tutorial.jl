include("./HiC_spector.jl");


#####Calculating reproducibility scores using A549 data

#The contact maps are obtained by binning the human genome in 40kb. 

hg19_info=define_hg19_genome();
bin_size=40000;
chr2bins,bin2loc=generate_arbitrary_mapping_files(hg19_info,bin_size);

#The number of eigenvectors (suggested value=20)

r=20;

#the reproducibility score Q for 23 chromosomes, 1 to 22, and X
Q=zeros(23);

###these arrays are used for benchmark only
elasped_time=zeros(23);
mem=zeros(23);

for chr_num=1:23;

	display(chr_num);

	chr_string=change_chr(hg19_info,chr_num);

	map_file1="./data/A549/A549C-HindIII-R1_"*chr_string*".inter";
	map_file2="./data/A549/A549D-HindIII-R2_"*chr_string*".inter";

	X1=readdlm(map_file1,Int64);
	X2=readdlm(map_file2,Int64);

	ib=find(bin2loc[1,:].==chr_num-1);
	N=length(ib);

	M1=sparse(floor(Int64,X1[:,1]/bin_size)+1,floor(Int64,X1[:,2]/bin_size)+1,X1[:,3],N,N);
	M2=sparse(floor(Int64,X2[:,1]/bin_size)+1,floor(Int64,X2[:,2]/bin_size)+1,X2[:,3],N,N);

	M1=full(M1);
	M2=full(M2);
	
	evs,a1,a2=get_reproducibility(M1,M2,r);
	Q[chr_num]=evs;

	#######the next few lines can be used for benchmark##############
	#info=@timed get_reproducibility(M1,M2,r);
	#evs=info[1][1];
	#Q[chr_num]=mean(evs);
	#elasped_time[chr_num]=info[2];
	#mem[chr_num]=info[3];

end


#####Other analysis using MCF7 data

data_loc="./data/MCF7-WT/";

#The contact maps are obtained by binning the human genome in 250kb. 

hg19_info=define_hg19_genome();
bin_size=250000;
chr2bins,bin2loc=generate_arbitrary_mapping_files(hg19_info,bin_size);

##Find the distance dependency of intro-chromosomal interaction frequency.

chr_num=10;
input_file=data_loc*"HiCStein-MCF7-WT__hg19__genome__C-250000-iced__"*change_chr(hg19_info,chr_num)*"__"*change_chr(hg19_info,chr_num)*"__cis.matrix";
X=readtable(input_file,header=true,separator='\t');
W=X[:,2:end];
W=array(W);
W[isnan(W)]=0;

xs_all, expect=get_expect_vs_d_single_chr_v0(W,chr2bins,bin_size);

using PyPlot;
PyPlot.plot(log10(xs_all),log10(expect));

##Matrix Balancing: turn W to W_balance #####
#the row sums and columns sum of W_balance are all 1, except the empty rows/columns
x,W_balance=knight_ruiz(W);

##Find A/B compartments

f_W=get_f_W(W,expect);
loc,span,ev_whole,cpt=get_compartment_A_B(W,f_W);

ev1=ev_whole[:,1];
#ev_whole records the leading eigenvector of the covariance matrix, ev1 reported the compartment. 
#bins with +ve and -ve values in ev1 correspond to different compartments. As by convention compartment A refers to the expressed
#part whereas compartment B refers to the lowly expressed part, extra information is required to determine which sign corresponds to which compartment.
#the value of ev1 is zero if the bin have no read mapped.

#to obtain the genomic coordinates, use

output=report_compartment(hg19_info,bin2loc,loc,span,ev1,chr_num);



