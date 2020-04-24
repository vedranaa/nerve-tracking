#include <math.h>
#include "mex.h"

#include "graph.h"
#include <vector>

void
mexFunction(int nout, mxArray *out[], 
            int nin, const mxArray *in[])
{

    if (nin != 3) 
        mexErrMsgTxt("Three arguments are required (nNodes,TerminalWeights,EdgeWeights)") ;
    if (nout > 2) 
        mexErrMsgTxt("Too many output arguments.");
  

    int nNodes = (int) *mxGetPr(in[0]);
    

    const int* twDim = mxGetDimensions(in[1]) ;
    int twRows = twDim[0] ;
    int twCols = twDim[1] ;
    double* twPt = mxGetPr(in[1]) ;
    if(twCols!=3)
        mexErrMsgTxt("The Terminal Weight matix should have 3 columns, (Node,sink,source).");

    
    const int* ewDim = mxGetDimensions(in[2]) ;
    int ewRows = ewDim[0] ;
    int ewCols = ewDim[1] ;
    double* ewPt = mxGetPr(in[2]) ;
    if(ewCols!=4)
        mexErrMsgTxt("The Terminal Weight matix should have 4 columns, (From,To,Capacity,Rev_Capacity).");
    
  
    typedef Graph<double,double,double> GraphType;
	GraphType G(static_cast<int>(nNodes), static_cast<int>(ewRows+twRows)); 
    G.add_node(nNodes);  
  
    for(int cTw=0;cTw<twRows;cTw++)
    {
        //Test for nodes in range
        int node=(int)twPt[cTw]-1;
        if(node<0 || node>=nNodes)
            mexErrMsgTxt("index out of bounds in TerminalWeight Matrix.");
        G.add_tweights(node,twPt[cTw+twRows],twPt[cTw+2*twRows]);
    }
    
    for(int cEw=0;cEw<ewRows;cEw++)
    {
        //Test for nodes in range
        int From=(int)ewPt[cEw]-1;
        int To=(int)ewPt[cEw+ewRows]-1;
        if(From<0 || From>=nNodes)
            mexErrMsgTxt("From index out of bounds in Edge Weight Matrix.");
        if(To<0 || To>=nNodes)
            mexErrMsgTxt("To index out of bounds in Edge Weight Matrix.");

        G.add_edge(From,To,ewPt[cEw+2*ewRows],ewPt[cEw+3*ewRows]);
    }

    double flow=G.maxflow();
    
    std::vector<int> SourceCut;
    for(int cNode=0;cNode<nNodes;cNode++)
    {
        if(G.what_segment(cNode)== GraphType::SOURCE)
            SourceCut.push_back(cNode+1);
    }
       
    out[0] = mxCreateDoubleMatrix(SourceCut.size(), 1, mxREAL) ;
    double* pOut=mxGetPr(out[0]);
    std::vector<int>::const_iterator Itt(SourceCut.begin());
    for(;Itt!=SourceCut.end();++Itt)
    {
        *pOut=*Itt;
        ++pOut;
    }
    
    if(nout==2)
    {
        out[1] = mxCreateDoubleMatrix(1, 1, mxREAL) ;
        *mxGetPr(out[1])=flow;
    }
    
}