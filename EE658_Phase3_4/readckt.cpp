/*=======================================================================
  A simple parser for "self" format
  The circuit format (called "self" format) is based on outputs of
  a ISCAS 85 format translator written by Dr. Sandeep Gupta.
  The format uses only integers to represent circuit information.
  The format is as follows:
1        2        3        4           5           6 ...
------   -------  -------  ---------   --------    --------
0 GATE   outline  0 IPT    #_of_fout   #_of_fin    inlines
                  1 BRCH
                  2 XOR(currently not implemented)
                  3 OR
                  4 NOR
                  5 NOT
                  6 NAND
                  7 AND
1 PI     outline  0        #_of_fout   0
2 FB     outline  1 BRCH   inline
3 PO     outline  2 - 7    0           #_of_fin    inlines
                                    Author: Chihang Chen
                                    Date: 9/16/94
=======================================================================*/

/*=======================================================================
  - Write your program as a subroutine under main().
    The following is an example to add another command 'lev' under main()
enum e_com {READ, PC, HELP, QUIT, LEV};
#define NUMFUNCS 5
int cread(), pc(), quit(), lev();
struct cmdstruc command[NUMFUNCS] = {
   {"READ", cread, EXEC},
   {"PC", pc, CKTLD},
   {"HELP", help, EXEC},
   {"QUIT", quit, EXEC},
   {"LEV", lev, CKTLD},
};
lev()
{
   ...
}
=======================================================================*/
#include <algorithm>
#include <bits/stdc++.h>
#include <bitset>
#include <chrono>
#include <cmath>
#include <cstring>
#include <ctype.h>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <iterator>
#include <map>
#include <sstream>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <string>
#include <vector> // for 2D vector;

using namespace std;
using namespace std::chrono;
#define MAXLINE 81 /* Input buffer size */
#define MAXNAME 31 /* File name size */

#define Upcase(x) ((isalpha(x) && islower(x)) ? toupper(x) : (x))
#define Lowcase(x) ((isalpha(x) && isupper(x)) ? tolower(x) : (x))

enum e_com {
  ATPG,
  READ,
  PC,
  HELP,
  QUIT,
  LEV,
  LOGICSIM,
  RFL,
  PFS,
  DFS,
  RTG,
  DALG,
  ATPG_DET
};
enum e_state { EXEC, CKTLD };      /* Gstate values */
enum e_ntype { GATE, PI, FB, PO }; /* column 1 of circuit format */
enum e_gtype { IPT, BRCH, XOR, OR, NOR, NOT, NAND, AND }; /* gate types */

struct cmdstruc {
  char name[MAXNAME];     /* command syntax */
  void (*fptr)(char *cp); /* function pointer of the commands */
  enum e_state state;     /* execution state sequence */
};

struct NSTRUC {
  unsigned indx;               /* node index(from 0 to NumOfLine - 1 */
  unsigned num;                /* line number(May be different from indx */
  enum e_gtype type;           /* gate type */
  unsigned fin;                /* number of fanins */
  unsigned fout;               /* number of fanouts */
  NSTRUC **unodes;             /* pointer to array of up nodes */
  NSTRUC **dnodes;             /* pointer to array of down nodes */
  int level;                   /* level of the gate output */
  vector<int> vec_value = {0}; /* logic value of the node */
  unsigned long int pfs_value; /*logic value for pfs */
  string vec_bits = "0";       /* parallel fault simulation */
  vector<int> dfs_fault_list = {0};
  vector<int> dfs_mode = {0};
  int label[20000]; // for D-alg;
  int d_value[20000];
};

/*----------------- Command definitions ----------------------------------*/
#define NUMFUNCS 14
void cread(char *cp), pc(char *cp), help(char *cp), quit(char *cp),
    lev(char *cp), logicsim(char *cp), rfl(char *cp), pfs(char *cp),
    dfs(char *cp), rtg(char *cp), dalg(char *cp), atpg_det(char *cp),
    podem(char *cp), atpg(char *cp), atpg_part4();
void clear(), allocate();
string gname(int tp);
struct cmdstruc command[NUMFUNCS] = {{"ATPG", atpg, EXEC},
                                     {"READ", cread, EXEC},
                                     {"PC", pc, CKTLD},
                                     {"HELP", help, EXEC},
                                     {"QUIT", quit, EXEC},
                                     {"LEV", lev, CKTLD},
                                     {"LOGICSIM", logicsim, CKTLD},
                                     {"RFL", rfl, CKTLD},
                                     {"DFS", dfs, CKTLD},
                                     {"PFS", pfs, CKTLD},
                                     {"RTG", rtg, CKTLD},
                                     {"DALG", dalg, CKTLD},
                                     {"PODEM", podem, CKTLD},
                                     {"ATPG_DET", atpg_det, EXEC}};

/*------------------------------------------------------------------------*/
enum e_state Gstate = EXEC; /* global exectution sequence */
NSTRUC *Node;               /* dynamic array of nodes */
NSTRUC **Pinput;            /* pointer to array of primary inputs */
NSTRUC **Poutput;           /* pointer to array of primary outputs */
int Nnodes;                 /* number of nodes */
int Npi;                    /* number of primary inputs */
int Npo;                    /* number of primary outputs */
int Done = 0;               /* status bit to terminate program */
char filename[MAXNAME];     /* store file name */
int D = 3;
int D_bar = 4;
int X = 2;
/*------------------------------------------------------------------------*/

// For PODEM

class podem_class {
  NSTRUC *np;
  int Nfaults;    // number of total faults
  int faultindx;  // line indx of the fault
  int faultvalue; // fault s-a-vaule
  int next_objective;
  int object_value;
  int pos;
  int count;
  int back_gate;
  bool key;
  unsigned int *value1;
  unsigned int *value2; // good value of gate
  unsigned int *value3;
  unsigned int *value4; // faulty value of gate
  int *D_frontier;      // D_frontier array
  int *task;
  bool path_find;
  bool isDetected;
  bool pathFound;

  // ------- For simulation --------
  int **levelEvents; // event list for each level
  int *levelLen;     // event list length
  int numlevels;     // total number of levels in wheel
  int current_level; // current level
  int *activation;   // activation list for the current level in circuit
  int activated;     // length of the activation list

public:
  int podem(int, int, string);
  void ActFault(int);      // activite the fault
  int backtrace(int, int); // backtrace to input
  void DFrontier(int);     // find d-frontier
  void objective(int, bool);
  bool podem_recursion(int,
                       int); // recursive podem check if the fault is detected
  bool possible_pathto_PO(int); // check x-path from D-frontier to PO
  bool
  Check_fault_activation(int,
                         int); // to make sure that fault is getting excited
                               // -------- For simulation -------
  void Store_lev_node(int, int);
  void Setup_levl();
  int Return_node_index();
  void left_node_sim();
  void right_node_sim();
  void create_vector();
};

podem_class *PODEM_inst;
int podem_update_level = 0;
vector<int> podem_node_index_queue; // used in levelization for podem

/*-----------------------------------------------------------------------
input: nothing
output: nothing
called by: shell
description:
  This is the main program of the simulator. It displays the prompt, reads
  and parses the user command, and calls the corresponding routines.
  Commands not reconized by the parser are passed along to the shell.
  The command is executed according to some pre-determined sequence.
  For example, we have to read in the circuit description file before any
  action commands.  The code uses "Gstate" to check the execution
  sequence.
  Pointers to functions are used to make function calls which makes the
  code short and clean.
-----------------------------------------------------------------------*/
int main() {
  // enum e_com com;
  int com;
  char cline[MAXLINE], wstr[MAXLINE], *cp;

  while (!Done) {
    printf("\nCommand>");
    fgets(cline, MAXLINE, stdin); // get input;
    if (sscanf(cline, "%s", wstr) != 1)
      continue;
    cp = wstr;
    while (*cp) {
      *cp = Upcase(*cp);
      cp++;
    }
    cp = cline + strlen(wstr);
    com = ATPG;
    while (com < NUMFUNCS && strcmp(wstr, command[com].name)) {
      ++com;
    }
    if (com < NUMFUNCS) {
      if (command[com].state <= Gstate)
        (*command[com].fptr)(cp);
      else
        printf("Execution out of sequence!\n");
    } else
      system(cline);
  }
  return 0;
}

/*-----------------------------------------------------------------------
input: circuit description file name
output: nothing
called by: main
description:
  This routine reads in the circuit description file and set up all the
  required data structure. It first checks if the file exists, then it
  sets up a mapping table, determines the number of nodes, PI's and PO's,
  allocates dynamic data arrays, and fills in the structural information
  of the circuit. In the ISCAS circuit description format, only upstream
  nodes are specified. Downstream nodes are implied. However, to facilitate
  forward implication, they are also built up in the data structure.
  To have the maximal flexibility, three passes through the circuit file
  are required: the first pass to determine the size of the mapping table
  , the second to fill in the mapping table, and the third to actually
  set up the circuit information. These procedures may be simplified in
  the future.
-----------------------------------------------------------------------*/
string ckt_name = "";
int Nfb;
NSTRUC **FB_array;
void cread(char *cp) {
  ckt_name.clear();

  char buf[MAXLINE];
  int ntbl, *tbl, i, j, k, nd, tp, fo, fi, ni = 0, no = 0, nb = 0;
  FILE *fd;
  NSTRUC *np;
  sscanf(cp, "%s", buf);
  stringstream S(buf);
  getline(S, ckt_name, '.');

  if ((fd = fopen(buf, "r")) == NULL) {
    printf("File %s does not exist!\n", buf);
    return;
  }
  if (Gstate >= CKTLD) {
    clear();
  }

  Nnodes = Npi = Npo = ntbl = Nfb = 0;
  while (fgets(buf, MAXLINE, fd) != NULL) {
    if (sscanf(buf, "%d %d", &tp, &nd) == 2) {
      if (ntbl < nd)
        ntbl = nd;
      Nnodes++;
      if (tp == PI)
        Npi++;
      else if (tp == PO)
        Npo++;
      else if (tp == FB)
        Nfb++;
    }
  }

  tbl = (int *)malloc(++ntbl * sizeof(int));

  fseek(fd, 0L, 0);
  i = 0;

  while (fgets(buf, MAXLINE, fd) != NULL) {
    if (sscanf(buf, "%d %d", &tp, &nd) == 2)
      tbl[nd] = i++;
  }
  allocate();
  fseek(fd, 0L, 0);

  while (fscanf(fd, "%d %d", &tp, &nd) != EOF) {
    np = &Node[tbl[nd]];
    np->num = nd;
    if (tp == PI)
      Pinput[ni++] = np;
    else if (tp == PO) {
      Poutput[no++] = np;
    } else if (tp == FB) {
      FB_array[nb++] = np;
    }
    switch (tp) {
    case PI:
    case PO:
    case GATE:
      fscanf(fd, "%d %d %d", &np->type, &np->fout, &np->fin);
      break;
    case FB:
      np->fout = np->fin = 1;
      fscanf(fd, "%d", &np->type);
      break;
    default:
      cout << "Unknown node type!\n";
      exit(-1);
    }
    np->unodes = new NSTRUC *[np->fin];
    np->dnodes = new NSTRUC *[np->fout];
    // np->unodes = (NSTRUC **)malloc(np->fin * sizeof(NSTRUC *));
    // np->dnodes = (NSTRUC **)malloc(np->fout * sizeof(NSTRUC *));
    for (i = 0; i < np->fin; i++) {
      fscanf(fd, "%d", &nd);
      np->unodes[i] = &Node[tbl[nd]];
    }
    for (i = 0; i < np->fout; np->dnodes[i++] = NULL) {
      ;
    }
  }
  for (i = 0; i < Nnodes; i++) {
    for (j = 0; j < Node[i].fin; j++) {
      np = Node[i].unodes[j];
      k = 0;
      while (np->dnodes[k] != NULL)
        k++;
      np->dnodes[k] = &Node[i];
    }
  }

  fclose(fd);
  Gstate = CKTLD;
  cout << "==> OK\n";
}

/*-----------------------------------------------------------------------
input: nothing
output: nothing
called by: main
description:
  The routine prints out the circuit description from previous READ command.
-----------------------------------------------------------------------*/
void pc(char *cp) {
  int i, j;
  NSTRUC *np;
  printf(" Node   Type \tIn     \t\t\tOut    \n");
  printf("------ ------\t-------\t\t\t-------\n");
  for (i = 0; i < Nnodes; i++) {
    np = &Node[i];
    printf("\t\t\t\t\t");
    for (j = 0; j < np->fout; j++)
      printf("%d ", np->dnodes[j]->num);
    cout << "\r" << setw(5) << np->num << "  " << gname(np->type) << "\t";
    for (j = 0; j < np->fin; j++)
      printf("%d ", np->unodes[j]->num);
    printf("\n");
  }
  printf("Primary inputs:  ");
  for (i = 0; i < Npi; i++)
    printf("%d ", Pinput[i]->num);
  printf("\n");
  printf("Primary outputs: ");
  for (i = 0; i < Npo; i++)
    printf("%d ", Poutput[i]->num);
  printf("\n\n");
  printf("Number of nodes = %d\n", Nnodes);
  printf("Number of primary inputs = %d\n", Npi);
  printf("Number of primary outputs = %d\n", Npo);
}
/*-----------------------------------------------------------------------
input:
output:
called by: lev
description:
  leveliztion.
-----------------------------------------------------------------------*/
int lev_max = 0;
vector<vector<int>> vec_lev;
void update_level() {
  lev_max = 0;
  vec_lev.clear();

  if (podem_update_level) {
    podem_node_index_queue.clear();
  }
  // reset all global variables about levelization;
  NSTRUC *np;
  vector<int> vec_eachlev; // update each level;
  for (int i = 0; i < Nnodes; i++) {
    np = &Node[i];
    if (np->type == 0) {
      np->level = 0;
      if (podem_update_level) {
        podem_node_index_queue.push_back(np->indx);
      }
    } else
      np->level = -1;
  }
  // initilizing levels of the circuit and calculating number of gates;

  // determine all the node levels:
  int Tcount;
  do {
    Tcount = 0;
    for (int i = 0; i < Nnodes; i++) {
      np = &Node[i];
      int Scount = 0;
      if (np->level == -1) {
        for (unsigned int j = 0; j < np->fin; j++) {
          if (np->unodes[j]->level == -1)
            ++Scount;
        }
        if (!Scount) {
          int max = 0;
          for (unsigned int j = 0; j < np->fin; j++) {
            if (np->unodes[j]->level >= max)
              max = np->unodes[j]->level;
          }
          np->level = max + 1;
          if (lev_max < (max + 1)) {
            lev_max = max + 1;
          }
        }
      }
    }
    for (int i = 0; i < Nnodes; i++) {
      np = &Node[i];
      if (np->level == -1)
        ++Tcount;
    }
  } while (Tcount);

  for (int m = 0; m <= lev_max; m++) {
    for (int n = 0; n < Nnodes; n++) {
      np = &Node[n];
      if (np->level == m) {
        vec_eachlev.push_back(n); // push level j's information into vector;
        if (podem_update_level) {
          podem_node_index_queue.push_back(np->indx);
        }
      }
    }
    vec_lev.push_back(vec_eachlev);
    vec_eachlev.clear();
  } // push all levels' information into vector;
}

void lev(char *cp) {
  char buf[MAXLINE];
  ofstream myfile;
  sscanf(cp, "%s", buf);
  myfile.open(buf);

  NSTRUC *np;
  int i;
  int number_of_gates = 0;

  for (i = 0; i < Nnodes; i++) {
    np = &Node[i];
    if (np->type >= 2 && np->type <= 7)
      number_of_gates = number_of_gates + 1;
  }

  update_level();

  // write the circuit informations in output file;

  myfile << ckt_name << "\n";
  myfile << "#PI: " << Npi << "\n";
  myfile << "#PO: " << Npo << "\n";
  myfile << "#Nodes: " << Nnodes << "\n";
  myfile << "#Gates: " << number_of_gates << "\n";

  // for (i = 0; i < Nnodes; i++) {
  //   np = &Node[i];
  //   myfile << np->num << " " << np->level << "\n";
  // }
  // cout << lev_max << "============";
  for (int j = 0; j <= lev_max; j++) {
    for (unsigned int r = 0; r < vec_lev[j].size(); r++) {
      np = &Node[vec_lev[j][r]];
      // cout << j << "================" << np << endl;
      myfile << np->num << " " << np->level << "\n";
    }
  }

  myfile.close();
}

/*-----------------------------------------------------------------------
input: node pointer, the number of patterns, flag
output:
called by: logicsim
description:
  gate logic;
-----------------------------------------------------------------------*/

void not_gate(NSTRUC *np, int m, int flag) {
  if (flag == 0) {
    if (np->unodes[0]->vec_value[m] == 1)
      np->vec_value[m] = (0);
    if (np->unodes[0]->vec_value[m] == 0)
      np->vec_value[m] = (1);
    if (np->unodes[0]->vec_value[m] == X) {
      np->vec_value[m] = (X);
    }
    np->dfs_mode[m] = 0;
  }
  if (flag == 1) {
    unsigned long int temp = np->unodes[0]->pfs_value;
    temp = ~temp;
    // cout << np->num << "pfs_value: " << temp << endl;
    np->pfs_value = (temp);
  }
}

void xor_gate(NSTRUC *np, int m, int flag) {
  if (flag == 0) {
    vector<int> temp1;
    vector<int> temp2;
    int count1 = 0, count2 = 0;
    for (unsigned int i = 0; i < np->fin; i++) {
      if (np->unodes[i]->vec_value[m] == 0) {
      }
      if (np->unodes[i]->vec_value[m] == 1) {
        count1++;
      }
      if (np->unodes[i]->vec_value[m] == X) {
        count2++;
      }
    }
    if (count2) {
      np->vec_value[m] = (X);
    }
    if (count1 % 2 == 1) {
      np->vec_value[m] = (1);
    }
    if (count1 % 2 == 0) {
      np->vec_value[m] = (0);
    }
  }
  if (flag == 1) {
    unsigned long int temp = np->unodes[0]->pfs_value;
    if (np->fin > 1) {
      for (unsigned int i = 1; i < np->fin; i++) {
        temp = temp ^ (np->unodes[i]->pfs_value);
      }
    }
    // cout << np->num << "pfs_value: " << temp << endl;
    np->pfs_value = (temp);
  }
}

void or_gate(NSTRUC *np, int m, int flag) {
  if (flag == 0) {
    int count1 = 0, count2 = 0;
    for (unsigned int i = 0; i < np->fin; i++) {
      if (np->unodes[i]->vec_value[m] == 1) {
        count1++;
      }
      if (np->unodes[i]->vec_value[m] == X) {
        count2++;
      }
      if (count1) {

        np->dfs_mode[m] = 1;

        np->vec_value[m] = (1);
      } else if (count2) {
        np->vec_value[m] = (2);
      } else {

        np->dfs_mode[m] = 0;

        np->vec_value[m] = (0);
      }
    }
  }
  if (flag == 1) {
    unsigned long int temp = np->unodes[0]->pfs_value;
    if (np->fin > 1) {
      for (unsigned int i = 1; i < np->fin; i++) {
        temp = temp | (np->unodes[i]->pfs_value);
      }
    }
    // cout << np->num << "pfs_value: " << temp << endl;
    np->pfs_value = (temp);
  }
}

void nor_gate(NSTRUC *np, int m, int flag) {
  if (flag == 0) {
    int count1 = 0, count2 = 0;
    for (unsigned int i = 0; i < np->fin; i++) {
      if (np->unodes[i]->vec_value[m] == 1) {
        count1++;
      }
      if (np->unodes[i]->vec_value[m] == 2) {
        count2++;
      }
      if (count1) {

        np->dfs_mode[m] = 1;

        np->vec_value[m] = (0);
      } else if (count2) {
        np->vec_value[m] = (2);
      } else {

        np->dfs_mode[m] = 0;

        np->vec_value[m] = (1);
      }
    }
  }
  if (flag == 1) {
    unsigned long int temp = np->unodes[0]->pfs_value;
    if (np->fin > 1) {
      for (unsigned int i = 1; i < np->fin; i++) {
        temp = temp | (np->unodes[i]->pfs_value);
      }
    }
    temp = ~temp;
    // cout << np->num << "pfs_value: " << temp << endl;
    np->pfs_value = (temp);
  }
}

void nand_gate(NSTRUC *np, int m, int flag) {
  if (flag == 0) {
    int count1 = 0, count2 = 0, count3 = 0;
    for (unsigned int i = 0; i < np->fin; i++) {
      if (np->unodes[i]->vec_value[m] == 0) {
        count1++;
      }
      if (np->unodes[i]->vec_value[m] == X) {
        count2++;
      }
    }
    if (count1) {
      np->dfs_mode[m] = 1;

      np->vec_value[m] = (1);
    } else if (count2) {
      np->vec_value[m] = (X);
    } else {

      np->dfs_mode[m] = 0;

      np->vec_value[m] = (0);
    }
  }
  if (flag == 1) {
    unsigned long int temp = np->unodes[0]->pfs_value;
    if (np->fin > 1) {
      for (unsigned int i = 1; i < np->fin; i++) {
        temp = temp & (np->unodes[i]->pfs_value);
      }
    }
    temp = ~temp;
    // cout << np->num << "pfs_value: " << temp << endl;
    np->pfs_value = (temp);
  }
}
void and_gate(NSTRUC *np, int m, int flag) {
  if (flag == 0) {
    int count1 = 0, count2 = 0;
    for (unsigned int i = 0; i < np->fin; i++) {
      if (np->unodes[i]->vec_value[m] == 0) {
        count1++;
      }
      if (np->unodes[i]->vec_value[m] == 2) {
        count2++;
      }
    }
    if (count1) {
      np->dfs_mode[m] = 1;

      np->vec_value[m] = (0);
    } else if (count2) {
      np->vec_value[m] = (2);
    } else {
      np->dfs_mode[m] = 0;

      np->vec_value[m] = (1);
    }
  }
  if (flag == 1) {
    unsigned long int temp = np->unodes[0]->pfs_value;
    if (np->fin > 1) {
      for (unsigned int i = 1; i < np->fin; i++) {
        temp = temp & (np->unodes[i]->pfs_value);
      }
    }
    // cout << np->num << "pfs_value: " << temp << endl;
    np->pfs_value = (temp);
  }
}

/*-----------------------------------------------------------------------
input: flag
output:
called by: logicsim
description:
  logic simulation;
-----------------------------------------------------------------------*/
vector<int> vec_inputpattern;
vector<int> vec_input_id;
vector<vector<int>> vec_logic;
void update_logic(int flag, int number_patterns) {
  NSTRUC *np;
  for (int i = 0; i < Nnodes; i++) {
    np = &Node[i];
    np->vec_value.clear();
    np->vec_value.assign(number_patterns, X);
    np->vec_value.shrink_to_fit();
    np->dfs_mode.clear();
    np->dfs_mode.assign(number_patterns, -1);
    np->dfs_mode.shrink_to_fit();
  }
  // reset all vec_value;
  for (int m = 0; m < number_patterns; m++) {
    for (unsigned int i = 0; i < vec_lev[0].size(); i++) {
      np = &Node[vec_lev[0][i]];
      for (int j = 0; j < Npi; j++) {
        if (np->num == (unsigned int)vec_input_id[j]) {
          np->vec_value[m] = (vec_logic[m][j]);
        }
      }
    }
    // set all primary inputs' value;
    for (int i = 1; i <= lev_max; i++) {
      for (unsigned int j = 0; j < vec_lev[i].size(); j++) {
        np = &Node[vec_lev[i][j]];
        // cout << np->num << "================" << endl;
        switch (np->type) {
        case 1:
          np->vec_value[m] = (np->unodes[0]->vec_value[m]);
          break;
        case 2:
          xor_gate(np, m, flag);
          break;
        case 3:
          or_gate(np, m, flag);
          break;
        case 4:
          nor_gate(np, m, flag);
          break;
        case 5:
          not_gate(np, m, flag);
          break;
        case 6:
          nand_gate(np, m, flag);
          break;
        case 7:
          and_gate(np, m, flag);
          break;
        default:
          break;
        }
        // cout << m << "------" << np->level << "----------" <<
        // np->vec_value[m]
        //      << endl;
      }
    }
  }
  // cout << "update logic DONE" << endl;
}

void logicsim(char *cp) {
  update_level();
  int flag = 0;
  char buf[MAXLINE];

  char *spaceIndx;
  spaceIndx = strchr(cp + 1, ' ');
  *spaceIndx = '\0';
  // get information from input files;

  sscanf(cp + 1, "%s", buf);
  ifstream fd;
  fd.open(buf);

  if (fd.is_open() == 0) {
    cout << "File " << buf << " does not exist!\n";
    return;
  }

  string line;
  int number_patterns = 0; // reset number_patterns;
  vec_inputpattern.clear();
  vec_input_id.clear();
  vec_logic.clear();

  while (!fd.eof()) {
    getline(fd, line);
    if (line.length() != 0) {
      ++number_patterns;
      vector<string> seglist;
      stringstream split_sentence(line);
      string segment;
      while (getline(split_sentence, segment, ',')) {
        seglist.push_back(segment);
      }
      for (unsigned int m = 0; m < seglist.size(); m++) {
        if (seglist[m] == "X") {
          seglist[m] = "0";
        }
        // temp = int(line[m]) - '0'; // for parallel;
        int temp = 0;
        stringstream string_to_int(seglist[m]);
        string_to_int >> temp;
        vec_inputpattern.push_back(temp);
      }
      if (number_patterns == 1) {
        vec_input_id = vec_inputpattern;
        vec_inputpattern.clear();
      } else {
        vec_logic.push_back(vec_inputpattern);
        vec_inputpattern.clear();
      }
    }
  }
  fd.close();
  --number_patterns; // real input pattern;
  update_logic(flag, number_patterns);

  char *cp2 = spaceIndx + 1;
  sscanf(cp2, "%s", buf);
  ofstream fd2;
  fd2.open(buf);
  // write all the node levels to output file
  for (int i = 0; i < Npo; i++) {
    fd2 << Poutput[i]->num;
    if (i < Npo - 1) {
      fd2 << ',';
    }
  }
  fd2 << endl;
  for (int m = 0; m < number_patterns; m++) {
    for (int i = 0; i < Npo; i++) {
      char temp = char(Poutput[i]->vec_value[m]) + '0';
      if (Poutput[i]->vec_value[m] == 2) {
        temp = 'X';
      }
      fd2 << temp;
      if (i < Npo - 1) {
        fd2 << ',';
      }
    }
    fd2 << endl;
  }
  fd2.close();
}
/*-----------------------------------------------------------------------
input:
output:
called by: rfl
description:
  reduced fault list;
-----------------------------------------------------------------------*/

void rfl(char *cp) {
  int i;
  // for(i = 0; i<Nfb; i++) cout<< FB_array[i]->num<<" ";
  // for(i = 0; i<Npi; i++) cout<<Pinput[i]->num<<" ";

  char buf[MAXLINE];
  ofstream myfile;

  sscanf(cp, "%s", buf);
  myfile.open(buf);
  // FILE *fd;

  // write the circuit informations in output file

  // sscanf(cp+1, "%s", buf);

  // fd = fopen(buf,"w");
  // write all the node levels to output file
  for (i = 0; i < Npi; i++) {
    myfile << Pinput[i]->num << "@0\n";
    myfile << Pinput[i]->num << "@1\n";
    // fprintf(fd, "%d@%d\n",Pinput[i]->num, 0);
    // fprintf(fd, "%d@%d\n",Pinput[i]->num, 1);
  }
  for (i = 0; i < Nfb; i++) {
    myfile << FB_array[i]->num << "@0\n";
    myfile << FB_array[i]->num << "@1\n";
    // fprintf(fd, "%d@%d\n",FB_array[i]->num, 0);
    // fprintf(fd, "%d@%d\n",FB_array[i]->num, 1);
  }

  // fclose(fd);

  myfile.close();
}
/*-----------------------------------------------------------------------
input:
output:
called by:
description:
  logic function for parallel fault simulation;
-----------------------------------------------------------------------*/
unsigned long int bin_to_int(NSTRUC *np, int m, int size) {
  unsigned long int val = 0;
  int temp = size;
  for (int i = 0; i < temp; i++) {
    val = (unsigned long int)pow(2, i) * ((np->vec_bits[temp - i - 1]) - '0') +
          val;
  }
  // cout << "==============bad===========\n\n";
  // cout << val << '-' << np->num;
  // cout << "\n\n"; //debug;
  return val;
}

string int_to_bin(unsigned long int num, int digit) {
  int temp = digit;
  string itob(temp, '2');
  for (int i = 0; i < temp; i++) {
    int k = num >> i;
    if (k & 1)
      itob[temp - i - 1] = '1';
    else
      itob[temp - i - 1] = '0';
  }
  return itob;
}
/*-----------------------------------------------------------------------
input:
output:
called by: pfs
description:
  parallel fault simulation;
-----------------------------------------------------------------------*/
vector<int> vec_faultlist_wid;
vector<int> vec_faultlist_wvalue;
vector<int> vec_faultlist_pid;
vector<int> vec_faultlist_pvalue;
vector<string> vec_detectlist;

void update_pfs(int bitwidth, int number_patterns, int number_fault) {
  int flag = 1;
  NSTRUC *np;
  for (int m = 0; m < number_patterns; m++) {
    for (unsigned int i = 0; i < vec_lev[0].size(); i++) {

      np = &Node[vec_lev[0][i]];
      string vec_perbit(bitwidth, vec_logic[m][i] + '0');

      // cout << vec_perbit << endl;
      // for (unsigned int r = 0; r < vec_perbit.length(); r++) {
      //   np->vec_bits[r] = vec_perbit[r];
      // }
      np->vec_bits = vec_perbit;

      for (int k = 0; k < vec_faultlist_pid.size(); k++) {
        if (np->num == vec_faultlist_pid[k]) {
          np->vec_bits[k] = vec_faultlist_pvalue[k] + '0';
        }
      }
      np->pfs_value = bin_to_int(np, m, bitwidth); // binary to int;
    }

    for (int i = 1; i <= lev_max; i++) {
      for (int j = 0; j < vec_lev[i].size(); j++) {
        np = &Node[vec_lev[i][j]];
        switch (np->type) {
        case 1:
          np->pfs_value = np->unodes[0]->pfs_value;
          break;
        case 2:
          xor_gate(np, m, flag);
          break;
        case 3:
          or_gate(np, m, flag);
          break;
        case 4:
          nor_gate(np, m, flag);
          break;
        case 5:
          not_gate(np, m, flag);
          break;
        case 6:
          nand_gate(np, m, flag);
          break;
        case 7:
          and_gate(np, m, flag);
          break;
        default:
          break;
        }
        // cout << "=============" << np->num << "=============" <<
        // np->pfs_value << endl;
        np->vec_bits = (int_to_bin(np->pfs_value, bitwidth));
        for (int k = 0; k < vec_faultlist_pid.size(); k++) {
          if (np->num == vec_faultlist_pid[k]) {
            np->vec_bits[k] = vec_faultlist_pvalue[k] + '0';
          }
        }
        np->pfs_value = bin_to_int(np, m, bitwidth); // binary to int;
      }
      // inject fault at specific level;
    }
    // cout << "=========inject all level input===========" << endl;
    // cout << "after gate logic--------------" << endl;
    // level by level;
    for (int i = 0; i < Npo; i++) {
      np = Poutput[i];
      // cout << np->num << "\n" << np->vec_bits << endl;
      for (int j = 0; j < np->vec_bits.size(); j++) {
        if (np->vec_bits[j] != np->vec_bits.back()) {
          string id = to_string(vec_faultlist_pid[j]);
          string value = to_string(vec_faultlist_pvalue[j]);
          string fault = id + '@' + value;
          // cout << fault << "==========\n";
          int count = 0;
          for (int n = 0; n < vec_detectlist.size(); n++) {
            if (fault == vec_detectlist[n]) {
              ++count;
              break;
            }
          }
          if (!count) {
            vec_detectlist.push_back(fault);
          }
        }
      }
    }
  }
}

void pfs(char *cp) {

  int bitwidth = 32;
  update_level();
  vec_faultlist_wid.clear();
  vec_faultlist_wvalue.clear();
  vec_faultlist_pid.clear();
  vec_faultlist_pvalue.clear();
  vec_detectlist.clear();
  vec_input_id.clear();
  vec_inputpattern.clear();
  vec_logic.clear();
  char buf[MAXLINE];
  int number_patterns = 0;
  char *spaceIndx;
  spaceIndx = strchr(cp + 1, ' ');
  *spaceIndx = '\0';
  sscanf(cp + 1, "%s", buf);
  ifstream fd;
  fd.open(buf);
  if (fd.is_open() == 0) {
    cout << "File " << buf << " does not exist!\n";
    return;
  }
  string line;
  while (!fd.eof()) {
    getline(fd, line);
    if (line.length() != 0) {
      ++number_patterns;
      vector<string> seglist;
      stringstream split_sentence(line);
      string segment;
      while (getline(split_sentence, segment, ',')) {
        seglist.push_back(segment);
      }
      for (unsigned int m = 0; m < seglist.size(); m++) {
        if (seglist[m] == "X") {
          seglist[m] = "0";
        }
        int temp = 0;
        stringstream string_to_int(seglist[m]);
        string_to_int >> temp;
        vec_inputpattern.push_back(temp);
      }
      if (number_patterns == 1) {
        vec_input_id = vec_inputpattern;
        vec_inputpattern.clear();
      } else {
        vec_logic.push_back(vec_inputpattern);
        vec_inputpattern.clear();
      }
    }
  }
  --number_patterns;
  fd.close();
  // get information from input test pattern;

  int number_fault = 0;
  char *cp2 = spaceIndx + 1;
  spaceIndx = strchr(cp2, ' ');
  *spaceIndx = '\0';
  sscanf(cp2, "%s", buf);
  ifstream fd2;
  fd2.open(buf);
  if (fd2.is_open() == 0) {
    cout << "File " << buf << " does not exist!\n";
    return;
  }
  string line2;
  while (!fd2.eof()) {
    getline(fd2, line2);
    if (line2.length() != 0) {
      char *p1 = &line2[0];
      char *Indx;
      Indx = strchr(p1, '@');
      *Indx = '\0';
      int temp1, temp2;
      sscanf(p1, "%d", &temp1);
      sscanf(Indx + 1, "%d", &temp2);
      NSTRUC *np;
      for (int i = 0; i < Nnodes; i++) {
        np = &Node[i];
        if (np->num == (unsigned int)temp1) {
          vec_faultlist_wid.push_back(temp1);
          vec_faultlist_wvalue.push_back(temp2);
          break;
        }
      }
    }
  }
  fd2.close();

  number_fault = vec_faultlist_wid.size();
  int number_loop = number_fault / (bitwidth - 1) + 1;
  int index;
  for (int i = 0; i < number_loop; i++) {
    index = i * (bitwidth - 1);
    if (number_fault < (bitwidth - 1)) {
      for (int n = 0; n < number_fault; n++) {
        vec_faultlist_pid.push_back(vec_faultlist_wid[index + n]);
        vec_faultlist_pvalue.push_back(vec_faultlist_wvalue[index + n]);
      }
    } else {
      for (int j = 0; j < (bitwidth - 1); j++) {
        vec_faultlist_pid.push_back(vec_faultlist_wid[index + j]);
        vec_faultlist_pvalue.push_back(vec_faultlist_wvalue[index + j]);
      }
      number_fault = number_fault - (bitwidth - 1);
    }
    update_pfs(bitwidth, number_patterns, number_fault);
    vec_faultlist_pid.clear();
    vec_faultlist_pvalue.clear();
  }

  char *cp3 = spaceIndx + 1;
  sscanf(cp3, "%s", buf);
  ofstream fd3;
  fd3.open(buf);
  for (unsigned int i = 0; i < vec_detectlist.size(); i++) {
    fd3 << vec_detectlist[i] << endl;
  }
  fd3.close();
  // output file;

  // reset all global variables;
}
/*-----------------------------------------------------------------------
input:
output:
called by: dfs
description:
  parallel fault simulation;
-----------------------------------------------------------------------*/
void dfs_0(NSTRUC *p) {
  for (unsigned int r = 0; r < p->fin; r++) {
    for (int w = 0; w < p->unodes[r]->dfs_fault_list.size(); w++) {
      int match = 0;
      for (int k = 0; k < p->dfs_fault_list.size(); k++) {
        if (p->dfs_fault_list[k] == p->unodes[r]->dfs_fault_list[w]) {
          ++match;
          break;
        }
      }
      if (!match) {
        p->dfs_fault_list.push_back(p->unodes[r]->dfs_fault_list[w]);
      }
    }
  }
  // cout << p->num << " node mode 0 faultlist id: ";
  // for (int r = 0; r < p->dfs_fault_list.size(); r++) {
  //   cout << p->dfs_fault_list[r] << "-";
  // }
  // cout << endl;
}

void dfs_1(NSTRUC *p, int m) {
  int control_v;
  if ((p->type == 3) || ((p->type == 4))) {
    control_v = 1;
  }
  if ((p->type == 6) || ((p->type == 7))) {
    control_v = 0;
  }
  vector<int> common_v;
  for (int i = 0; i < Nnodes; i++) {
    NSTRUC *q;
    q = &Node[i];
    common_v.push_back(q->indx);
  }
  // cout << "initial common" << endl;
  // cout << p->num << " common_part: ";
  // for (int q = 0; q < common_v.size(); q++) {
  //   cout << common_v[q] << '-';
  // }
  // cout << endl;
  for (unsigned int r = 0; r < p->fin; r++) {
    if (p->unodes[r]->vec_value[m] == control_v) {
      vector<int> temp_v;
      for (int j = 0; j < p->unodes[r]->dfs_fault_list.size(); j++) {
        int match = 0;
        for (int q = 0; q < common_v.size(); q++) {
          if (p->unodes[r]->dfs_fault_list[j] == common_v[q]) {
            ++match;
            break;
          }
        }
        if (match) {
          temp_v.push_back(p->unodes[r]->dfs_fault_list[j]);
        }
      }
      common_v = temp_v;
      // cout << p->num << " common_part: ";
      // for (int q = 0; q < common_v.size(); q++){
      //   cout << common_v[q] << '-';
      // }
      // cout << endl;
    }
  }

  for (int i = 0; i < common_v.size(); i++) {
    p->dfs_fault_list.push_back(common_v[i]);
  }
  for (unsigned int r = 0; r < p->fin; r++) {
    if (p->unodes[r]->vec_value[m] == (1 - control_v)) {
      for (int j = 0; j < p->unodes[r]->dfs_fault_list.size(); j++) {
        for (int q = 0; q < p->dfs_fault_list.size(); q++) {
          if (p->unodes[r]->dfs_fault_list[j] == p->dfs_fault_list[q]) {
            p->dfs_fault_list[q] = -1;
          }
        }
      }
    }
  }
  p->dfs_fault_list.erase(
      remove(p->dfs_fault_list.begin(), p->dfs_fault_list.end(), -1),
      p->dfs_fault_list.end());
  // cout << p->num << " node mode 1 faultlist id: ";
  // for (int r = 0; r < p->dfs_fault_list.size(); r++) {
  //   cout << p->dfs_fault_list[r] << "-";
  // }
  // cout << endl;
}

vector<int> vec_faultlist_id;
vector<int> vec_faultlist_value;
void update_dfs(int number_patterns) {
  vec_faultlist_id.clear();
  vec_faultlist_value.clear();
  for (int m = 0; m < number_patterns; m++) {
    for (int i = 0; i < Nnodes; i++) {
      NSTRUC *np;
      np = &Node[i];
      np->dfs_fault_list.clear();
      np->dfs_fault_list.push_back(np->indx);
    }
    // cout << "initialize" << endl;
    for (int i = 1; i <= lev_max; i++) {
      for (unsigned int j = 0; j < vec_lev[i].size(); j++) {
        NSTRUC *p;
        p = &Node[vec_lev[i][j]];
        if ((p->type == 1) || (p->type == 2)) {
          p->dfs_mode[m] = 0;
        }
        if (p->dfs_mode[m] == 0) {
          dfs_0(p);
        } else {
          dfs_1(p, m);
        }
      }
    }
    // cout << "all done" << endl;
    for (int i = 0; i < Npo; i++) {
      for (int j = 0; j < Poutput[i]->dfs_fault_list.size(); j++) {
        int match = 0;
        int fault_v, num;
        NSTRUC *p;
        p = &Node[Poutput[i]->dfs_fault_list[j]];
        num = p->num;
        fault_v = 1 - p->vec_value[m];
        for (int r = 0; r < vec_faultlist_id.size(); r++) {
          if ((num == vec_faultlist_id[r]) &&
              (fault_v == vec_faultlist_value[r])) {
            ++match;
            break;
          }
        }
        if (!match) {
          vec_faultlist_id.push_back(p->num);
          vec_faultlist_value.push_back(fault_v);
        }
      }
    }
    // cout << "faultlist id: ";
    // for (int r = 0; r < vec_faultlist_id.size(); r++) {
    //   cout << vec_faultlist_id[r] << "-";
    // }
    // cout << endl;
  }
}

void dfs(char *cp) {
  vec_lev.clear();
  update_level(); // Initially levelize the circuit
  char buf[MAXLINE];

  char *spaceIndx;
  spaceIndx = strchr(cp + 1, ' ');
  *spaceIndx = '\0';

  // write the circuit informations in output file

  sscanf(cp + 1, "%s", buf);
  ifstream fd;
  fd.open(buf);

  if (fd.is_open() == 0) {
    // cout << "File " << buf << " does not exist!\n";
    return;
  }

  string line;
  int number_patterns = 0; // reset number_patterns;
  vec_inputpattern.clear();
  vec_input_id.clear();
  vec_logic.clear();

  while (!fd.eof()) {
    getline(fd, line);
    if (line.length() != 0) {
      ++number_patterns;
      vector<string> seglist;
      stringstream split_sentence(line);
      string segment;
      while (getline(split_sentence, segment, ',')) {
        seglist.push_back(segment);
      }
      for (unsigned int m = 0; m < seglist.size(); m++) {
        if (seglist[m] == "X") {
          seglist[m] = "0";
        }
        // temp = int(line[m]) - '0'; // for parallel;
        int temp = 0;
        stringstream string_to_int(seglist[m]);
        string_to_int >> temp;
        vec_inputpattern.push_back(temp);
      }
      if (number_patterns == 1) {
        vec_input_id = vec_inputpattern;
        vec_inputpattern.clear();
      } else {
        vec_logic.push_back(vec_inputpattern);
        vec_inputpattern.clear();
      }
    }
  }
  --number_patterns; // real pattern;
  int flag = 0;
  update_logic(flag, number_patterns); // doing logic simulation
  // int printFlag = 1;
  fd.close();

  char *cp2 = spaceIndx + 1;
  sscanf(cp2, "%s", buf);
  ofstream fd2;
  fd2.open(buf);
  vec_faultlist_id.clear();
  vec_faultlist_value.clear();
  // cout << "before dfs" << endl;
  update_dfs(number_patterns);
  // cout << "after dfs" << endl;
  for (int j = 0; j < vec_faultlist_id.size(); j++) {
    string id = to_string(vec_faultlist_id[j]);
    string value = to_string(vec_faultlist_value[j]);
    string fault = id + '@' + value;
    fd2 << fault << '\n';
  }
  vec_logic.clear();
  vec_input_id.clear();
  vec_faultlist_id.clear();
  vec_faultlist_value.clear();
  fd2.close();
  //*************************** below we will write operation to the output.txt
}

/*-----------------------------------------------------------------------
input: nothing
output: nothing
called by: rtg
description:
  decimal to binary conversion by using ascii.
-----------------------------------------------------------------------*/
string dec_to_bin(int num, int digit) {
  string itob((digit), '9');
  for (int i = 0; i < digit; i++) {
    int k = num >> i;
    if (k & 1)
      itob[i] = '1';
    else
      itob[i] = '0';
  }
  return itob;
}

/*-----------------------------------------------------------------------
input: nothing
output: nothing
called by: rtg
description:
  random test generation.
-----------------------------------------------------------------------*/
void rtg(char *cp) {
  vec_lev.clear();
  update_level();

  // cout<<"HERE";

  char buf[MAXLINE];
  char buf2[MAXLINE];

  int range;
  unsigned long int random_pattern;
  float fault_coverage;

  char *spaceIndx;
  spaceIndx = strchr(cp + 1, ' ');
  *spaceIndx = '\0';

  // first argument;
  int total_pattern = 0;
  sscanf(cp + 1, "%s", buf);
  // put your number from buf into num1;
  sscanf(buf, "%d", &total_pattern);
  // cout << num1 << '\n';

  char *cp2 = spaceIndx + 1;
  spaceIndx = strchr(cp2, ' ');
  *spaceIndx = '\0';
  sscanf(cp2, "%s", buf);
  // second argument;
  int frequency = 0;
  sscanf(buf, "%d", &frequency);
  // cout << num2 << '\n';

  char *cp3 = spaceIndx + 1;
  spaceIndx = strchr(cp3, ' ');
  *spaceIndx = '\0';
  sscanf(cp3, "%s", buf);
  // third argument;

  ofstream myfile1;
  myfile1.open(buf);

  char *cp4 = spaceIndx + 1;
  sscanf(cp4, "%s", buf2);
  // fourth argument;

  ofstream myfile2;
  myfile2.open(buf2);

  // total detected fault
  vector<int> total_faulty_nodes;
  vector<int> total_fault_types;

  string temp;
  NSTRUC *np;
  int temp2;
  srand(time(NULL));

  for (int i = 0; i < Npi; i++) {
    myfile1 << Pinput[i]->num;
    if (i < Npi - 1)
      myfile1 << ",";
  }
  myfile1 << "\n";

  for (int k = 0; k < Npi; k++) {
    np = Pinput[k];
    vec_input_id.push_back(np->num);
  }

  for (int i = 0; i < total_pattern / frequency; i++) {
    int number_patterns = frequency;
    vec_logic.clear();
    vec_faultlist_id.clear();
    vec_faultlist_value.clear();
    for (int j = 0; j < frequency; j++) {
      range = pow(2, Npi);
      random_pattern = rand() % range;
      temp = dec_to_bin(random_pattern, Npi);
      for (int k = 0; k < Npi; k++) {
        temp2 = temp[k] - '0'; // for parallel;
        vec_inputpattern.push_back(temp2);
        myfile1 << temp[k];
        if (k < Npi - 1)
          myfile1 << ",";
      }
      vec_logic.push_back(vec_inputpattern);
      vec_inputpattern.clear();
      myfile1 << "\n";
      temp.clear();
    }
    // generate random test patterns vector;
    int flag = 0;
    int real_pattern = number_patterns;
    update_logic(flag, real_pattern); // doing logic simulation
    update_dfs(
        real_pattern); // single deductive fault with the current input pattern
    for (int m = 0; m < vec_faultlist_id.size(); m++) {
      int match = 0;
      for (int n = 0; n < total_faulty_nodes.size(); n++) {
        if ((total_faulty_nodes[n] == vec_faultlist_id[m]) &&
            (total_fault_types[n] == vec_faultlist_value[m])) {
          match++;
        }
      }
      if (!match) {
        total_faulty_nodes.push_back(vec_faultlist_id[m]);
        total_fault_types.push_back(vec_faultlist_value[m]);
      }
    }
    fault_coverage =
        ((float)total_faulty_nodes.size()) / ((float)Nnodes) / ((float)2);
    fault_coverage = fault_coverage * 100;

    myfile2 << setprecision(2) << fixed << fault_coverage << "\n";
  }
  myfile1.close();
  myfile2.close();
}
/*-----------------------------------------------------------------------
input: nothing
output: nothing
called by: D-algorithm
description:
  ATPG to generate test vector to detect specific faults.
-----------------------------------------------------------------------*/
struct Frontier {
  int indx;
  int depth;
  int label = 0;
};
vector<vector<int>> Dalg_pattern;
vector<Frontier> j_frontier;
vector<Frontier> d_frontier;
vector<Frontier> temp_d_frontier;
vector<int> event_node_list;
vector<int> test_vector;
vector<int> podem_test_vector;

int depth = 0;
int unvisited = 1;
int undefined = 1;
int d_depth = 0;
void print_2d(vector<vector<int>> vec) {
  for (int i = 0; i < vec.size(); i++) {
    for (int j = 0; j < vec[i].size(); j++) {
      cout << vec[i][j] << '-';
    }
    cout << endl;
  }
}
void print_1d(vector<int> vec) {
  for (int i = 0; i < vec.size(); i++) {
    cout << vec[i] << '-';
  }
  cout << endl;
}
void global_reset_d() {
  j_frontier.clear();
  d_frontier.clear();
  temp_d_frontier.clear();
  event_node_list.clear();
  depth = 0;
  unvisited = 1;
  undefined = 1;
  d_depth = 0;
  for (int i = 0; i < Nnodes; i++) {
    NSTRUC *p;
    p = &Node[i];
    p->d_value[0] = X;
    p->label[0] = 0;
  }
}

void get_pattern(NSTRUC *np) {
  vector<int> temp_pattern;
  for (int i = 0; i < np->fin; i++) {
    temp_pattern.push_back(np->unodes[i]->indx);
  }
  Dalg_pattern.push_back(temp_pattern);
  temp_pattern.clear();

  if (np->type == 1) {
    vector<int> temp;
    for (int i = 0; i < np->fin; i++) {
      if (np->d_value[0] == D) {
        temp.push_back(1);
      }
      if (np->d_value[0] == D_bar) {
        temp.push_back(0);
      }
    }
    Dalg_pattern.push_back(temp);
    temp.clear();
  }
  if (np->type == 2) {
    vector<int> temp;
    int fin_num = np->fin;
    if (np->d_value[0] == D_bar) {
      temp.assign(2, 0);
      Dalg_pattern.push_back(temp);
      temp.assign(2, 1);
      Dalg_pattern.push_back(temp);
    }
    if (np->d_value[0] == D) {
      temp = {0, 1};
      Dalg_pattern.push_back(temp);
      temp = {1, 0};
      Dalg_pattern.push_back(temp);
    }
  }
  if (np->type == 3) {
    vector<int> temp;
    int fin_num = np->fin;
    if (np->d_value[0] == D_bar) {
      temp.assign(fin_num, 0);
      Dalg_pattern.push_back(temp);
    } else if (np->d_value[0] == D) {
      int max_range = (int)pow(2, fin_num);
      for (int i = 1; i < max_range; i++) {
        string S = dec_to_bin(i, fin_num);
        for (int j = 0; j < fin_num; j++) {
          temp.push_back(S[j] - '0');
        }
        Dalg_pattern.push_back(temp);
        temp.clear();
      }
    }
  }
  if (np->type == 4) {
    vector<int> temp;
    int fin_num = np->fin;
    if (np->d_value[0] == D) {
      temp.assign(fin_num, 0);
      Dalg_pattern.push_back(temp);
    } else if (np->d_value[0] == D_bar) {
      int max_range = (int)pow(2, fin_num);
      for (int i = 1; i < max_range; i++) {
        string S = dec_to_bin(i, fin_num);
        for (int j = 0; j < fin_num; j++) {
          temp.push_back(S[j] - '0');
        }
        Dalg_pattern.push_back(temp);
        temp.clear();
      }
    }
  }
  if (np->type == 5) {
    vector<int> temp;
    if (np->d_value[0] == D) {
      temp.push_back(0);
      Dalg_pattern.push_back(temp);
    } else if (np->d_value[0] == D_bar) {
      temp.push_back(1);
      Dalg_pattern.push_back(temp);
    }
  }
  if (np->type == 6) {
    vector<int> temp;
    int fin_num = np->fin;
    if (np->d_value[0] == D_bar) {
      temp.assign(fin_num, 1);
      Dalg_pattern.push_back(temp);
      temp.clear();
    } else if (np->d_value[0] == D) {
      int max_range = (int)pow(2, fin_num) - 1;
      for (int i = 0; i < max_range; i++) {
        string S = dec_to_bin(i, fin_num);
        for (int j = 0; j < fin_num; j++) {
          temp.push_back(S[j] - '0');
        }
        Dalg_pattern.push_back(temp);
        temp.clear();
      }
    }
  }
  if (np->type == 7) {
    vector<int> temp;
    int fin_num = np->fin;
    if (np->d_value[0] == D) {
      temp.assign(fin_num, 1);
      Dalg_pattern.push_back(temp);
      temp.clear();
    } else if (np->d_value[0] == D_bar) {
      int max_range = (int)pow(2, fin_num) - 1;
      for (int i = 0; i < max_range; i++) {
        string S = dec_to_bin(i, fin_num);
        for (int j = 0; j < fin_num; j++) {
          temp.push_back(S[j] - '0');
        }
        Dalg_pattern.push_back(temp);
        temp.clear();
      }
    }
  }
}
void get_frontier() {
  j_frontier.clear();
  if (!d_frontier.empty()) {
    d_depth = d_frontier.back().depth + 1;
  } else {
    d_depth = 0;
  }
  for (int i = 0; i < Nnodes; i++) {
    NSTRUC *np;
    np = &Node[i];
    if ((np->type == 1) || (np->type == 5)) {
      continue;
    }
    if (np->type == 2) {
      int fin_num = np->fin;
      int count1 = 0, count2 = 0, count3 = 0, count4 = 0, count5 = 0;
      for (int i = 0; i < fin_num; i++) {
        if (np->unodes[i]->d_value[0] == 0) {
          ++count1;
        }
        if (np->unodes[i]->d_value[0] == 1) {
          ++count2;
        }
        if (np->unodes[i]->d_value[0] == X) {
          ++count3;
        }
        if (np->unodes[i]->d_value[0] == D) {
          ++count4;
        }
        if (np->unodes[i]->d_value[0] == D_bar) {
          ++count5;
        }
      }

      if ((np->d_value[0] == 0) || (np->d_value[0] == 1)) {
        if (count3 == 2) {
          int temp = np->indx;
          Frontier J_frontier;
          J_frontier.indx = temp;
          j_frontier.push_back(J_frontier);
        }
      } else if (np->d_value[0] == X) {
        if ((count3 == 1) && ((count4 == 1) || (count5 == 1))) {
          int temp = np->indx;
          Frontier D_frontier;
          D_frontier.indx = temp;
          D_frontier.depth = d_depth;
          int match = 0;
          for (unsigned int j = 0; j < d_frontier.size(); j++) {
            if (d_frontier[j].indx == temp) {
              ++match;
              break;
            }
          }
          if (!match) {

            d_frontier.push_back(D_frontier);
          }
        }
      }
    }
    if (np->type == 3) {
      int fin_num = np->fin;
      int count1 = 0, count2 = 0, count3 = 0, count4 = 0, count5 = 0;
      int temp;
      for (int i = 0; i < fin_num; i++) {
        if (np->unodes[i]->d_value[0] == 0) {
          ++count1;
        }
        if (np->unodes[i]->d_value[0] == 1) {
          ++count2;
        }
        if (np->unodes[i]->d_value[0] == X) {
          ++count3;
        }
        if (np->unodes[i]->d_value[0] == D) {
          ++count4;
        }
        if (np->unodes[i]->d_value[0] == D_bar) {
          ++count5;
        }
      }
      if ((np->d_value[0] == 0) || (np->d_value[0] == 1)) {
        if ((count2 == 0) && (count3 != 0)) {
          int temp = np->indx;
          Frontier J_frontier;
          J_frontier.indx = temp;
          j_frontier.push_back(J_frontier);
        }
      } else if (np->d_value[0] == X) {
        if ((count2 == 0) && (count3 != 0) &&
            (((count4 == 0) && (count5 != 0)) ||
             ((count4 != 0) && (count5 == 0)))) {
          int temp = np->indx;
          Frontier D_frontier;
          D_frontier.indx = temp;
          D_frontier.depth = d_depth;
          int match = 0;
          for (unsigned int j = 0; j < d_frontier.size(); j++) {
            if (d_frontier[j].indx == temp) {
              ++match;
              break;
            }
          }
          if (!match) {

            d_frontier.push_back(D_frontier);
          }
        }
      }
    }
    if (np->type == 4) {
      int fin_num = np->fin;
      int count1 = 0, count2 = 0, count3 = 0, count4 = 0, count5 = 0;
      int temp;
      for (int i = 0; i < fin_num; i++) {
        if (np->unodes[i]->d_value[0] == 0) {
          ++count1;
        }
        if (np->unodes[i]->d_value[0] == 1) {
          ++count2;
        }
        if (np->unodes[i]->d_value[0] == X) {
          ++count3;
        }
        if (np->unodes[i]->d_value[0] == D) {
          ++count4;
        }
        if (np->unodes[i]->d_value[0] == D_bar) {
          ++count5;
        }
      }
      if ((np->d_value[0] == 0) || (np->d_value[0] == 1)) {
        if ((count2 == 0) && (count3 != 0)) {
          int temp = np->indx;
          Frontier J_frontier;
          J_frontier.indx = temp;
          j_frontier.push_back(J_frontier);
        }
      } else if (np->d_value[0] == X) {
        if ((count2 == 0) && (count3 != 0) &&
            (((count4 == 0) && (count5 != 0)) ||
             ((count4 != 0) && (count5 == 0)))) {
          int temp = np->indx;
          Frontier D_frontier;
          D_frontier.indx = temp;
          D_frontier.depth = d_depth;
          int match = 0;
          for (unsigned int j = 0; j < d_frontier.size(); j++) {
            if (d_frontier[j].indx == temp) {
              ++match;
              break;
            }
          }
          if (!match) {

            d_frontier.push_back(D_frontier);
          }
        }
      }
    }

    if (np->type == 6) {
      int fin_num = np->fin;
      int count1 = 0, count2 = 0, count3 = 0, count4 = 0, count5 = 0;
      int temp;
      for (int i = 0; i < fin_num; i++) {
        if (np->unodes[i]->d_value[0] == 0) {
          ++count1;
        }
        if (np->unodes[i]->d_value[0] == 1) {
          ++count2;
        }
        if (np->unodes[i]->d_value[0] == X) {
          ++count3;
        }
        if (np->unodes[i]->d_value[0] == D) {
          ++count4;
        }
        if (np->unodes[i]->d_value[0] == D_bar) {
          ++count5;
        }
      }
      if ((np->d_value[0] == 0) || (np->d_value[0] == 1)) {
        if ((count1 == 0) && (count3 != 0)) {
          int temp = np->indx;
          Frontier J_frontier;
          J_frontier.indx = temp;
          j_frontier.push_back(J_frontier);
        }
      } else if (np->d_value[0] == X) {
        if ((count1 == 0) && (count3 != 0) &&
            (((count4 == 0) && (count5 != 0)) ||
             ((count4 != 0) && (count5 == 0)))) {
          int temp = np->indx;
          Frontier D_frontier;
          D_frontier.indx = temp;
          D_frontier.depth = d_depth;
          int match = 0;
          for (unsigned int j = 0; j < d_frontier.size(); j++) {
            if (d_frontier[j].indx == temp) {
              ++match;
              break;
            }
          }
          if (!match) {
            d_frontier.push_back(D_frontier);
          }
        }
      }
    }
    if (np->type == 7) {
      int fin_num = np->fin;
      int count1 = 0, count2 = 0, count3 = 0, count4 = 0, count5 = 0;
      int temp;
      for (int i = 0; i < fin_num; i++) {
        if (np->unodes[i]->d_value[0] == 0) {
          ++count1;
        }
        if (np->unodes[i]->d_value[0] == 1) {
          ++count2;
        }
        if (np->unodes[i]->d_value[0] == X) {
          ++count3;
        }
        if (np->unodes[i]->d_value[0] == D) {
          ++count4;
        }
        if (np->unodes[i]->d_value[0] == D_bar) {
          ++count5;
        }
      }
      if ((np->d_value[0] == 0) || (np->d_value[0] == 1)) {
        if ((count1 == 0) && (count3 != 0)) {
          int temp = np->indx;
          Frontier J_frontier;
          J_frontier.indx = temp;
          j_frontier.push_back(J_frontier);
        }
      } else if (np->d_value[0] == X) {
        if ((count1 == 0) && (count3 != 0) &&
            (((count4 == 0) && (count5 != 0)) ||
             ((count4 != 0) && (count5 == 0)))) {
          int temp = np->indx;
          Frontier D_frontier;
          D_frontier.indx = temp;
          D_frontier.depth = d_depth;
          int match = 0;
          for (unsigned int j = 0; j < d_frontier.size(); j++) {
            if (d_frontier[j].indx == temp) {
              ++match;
              break;
            }
          }
          if (!match) {

            d_frontier.push_back(D_frontier);
          }
        }
      }
    }
  }
}
void backup_state(int depth) {
  for (int i = 0; i < Nnodes; i++) {
    NSTRUC *p;
    p = &Node[i];
    p->d_value[depth] = p->d_value[0];
    p->label[depth] = p->label[0];
  }
}
void restore_state(int depth) {
  for (int i = 0; i < Nnodes; i++) {
    NSTRUC *p;
    p = &Node[i];
    p->d_value[0] = p->d_value[depth];
    p->label[0] = p->label[depth];
  }
}
bool gate_logic(NSTRUC *np) {
  if (np->type == 1) {
    if (np->d_value[0] != X) {
      if (np->unodes[0]->d_value[0] != X) {
        if (np->d_value[0] == D) {
          if ((np->unodes[0]->d_value[0] != D) &&
              (np->unodes[0]->d_value[0] != 1) &&
              (np->unodes[0]->d_value[0] != X)) {
            // cout << "branch false-D: " << np->num << endl;
            return false;
          }
        }
        if (np->d_value[0] == D_bar) {
          if ((np->unodes[0]->d_value[0] != D_bar) &&
              (np->unodes[0]->d_value[0] != 0) &&
              (np->unodes[0]->d_value[0] != X)) {
            // cout << "branch false-D_bar: " << np->num << endl;
            return false;
          }
        }
        if (np->d_value[0] == 0) {
          if ((np->unodes[0]->d_value[0] != 0) &&
              (np->unodes[0]->d_value[0] != X)) {
            // cout << "branch false-0: " << np->num << endl;
            return false;
          }
        }
        if (np->d_value[0] == 1) {
          if ((np->unodes[0]->d_value[0] != 1) &&
              (np->unodes[0]->d_value[0] != X)) {
            // cout << "branch false-1: " << np->num << endl;
            return false;
          }
        }
      }
      if (np->unodes[0]->d_value[0] == X) {
        if (np->d_value[0] == D) {
          np->unodes[0]->d_value[0] = 1;
        }
        if (np->d_value[0] == D_bar) {
          np->unodes[0]->d_value[0] = 0;
        }
        if (np->d_value[0] == 1) {
          np->unodes[0]->d_value[0] = 1;
        }
        if (np->d_value[0] == 0) {
          np->unodes[0]->d_value[0] = 0;
        }
      }
    }
    if (np->d_value[0] == X) {
      np->d_value[0] = np->unodes[0]->d_value[0];
    }
  }
  if (np->type == 2) {
    int fin_num = np->fin;
    int count1 = 0, count2 = 0, count3 = 0, count4 = 0, count5 = 0;
    int temp;
    for (int i = 0; i < fin_num; i++) {
      if (np->unodes[i]->d_value[0] == 0) {
        ++count1;
      }
      if (np->unodes[i]->d_value[0] == 1) {
        ++count2;
      }
      if (np->unodes[i]->d_value[0] == X) {
        ++count3;
      }
      if (np->unodes[i]->d_value[0] == D) {
        ++count4;
      }
      if (np->unodes[i]->d_value[0] == D_bar) {
        ++count5;
      }
    }
    if (np->d_value[0] != X) {
      // int temp = np->indx;
      // Frontier D_frontier;
      // D_frontier.indx = temp;
      // for (unsigned int j = 0; j < d_frontier.size(); j++) {
      //   if (d_frontier[j].indx == temp) {
      //     d_frontier.erase(d_frontier.begin() + j);
      //     break;
      //   }
      // }
      if ((np->d_value[0] == D) || (np->d_value[0] == 1)) {
        if ((count1 == 2) || (count2 == 2) || (count4 == 2) || (count5 == 2) ||
            ((count1 == 1) && (count5 == 1)) ||
            ((count2 == 1) && (count4 == 1))) {
          // cout << "xor false: " << np->num << endl;
          return false;
        } else {
          if (np->d_value[0] == 1) {
            if ((count3 == 1) && (count1 == 1)) {
              for (int r = 0; r < np->fin; r++) {
                if (np->unodes[r]->d_value[0] == X) {
                  np->unodes[r]->d_value[0] = 1;
                }
              }
            }
            if ((count3 == 1) && (count2 == 1)) {
              for (int r = 0; r < np->fin; r++) {
                if (np->unodes[r]->d_value[0] == X) {
                  np->unodes[r]->d_value[0] = 0;
                }
              }
            }
          }
        }
      }
      if ((np->d_value[0] == D_bar) || (np->d_value[0] == 0)) {
        if (((count1 == 1) && (count2 == 1)) ||
            ((count1 == 1) && (count4 == 1)) ||
            ((count2 == 1) && (count5 == 1)) ||
            ((count4 == 1) && (count5 == 1))) {
          // cout << "xor false: " << np->num << endl;
          return false;
        } else {
          if (np->d_value[0] == 0) {
            if ((count3 == 1) && (count1 == 1)) {
              for (int r = 0; r < np->fin; r++) {
                if (np->unodes[r]->d_value[0] == X) {
                  np->unodes[r]->d_value[0] = 0;
                }
              }
            }
            if ((count3 == 1) && (count2 == 1)) {
              for (int r = 0; r < np->fin; r++) {
                if (np->unodes[r]->d_value[0] == X) {
                  np->unodes[r]->d_value[0] = 1;
                }
              }
            }
          }
        }
      }
    }
    if (np->d_value[0] == X) {
      // if ((count3 == 1) && ((count4 == 1) || (count5 == 1))) {
      //   int temp = np->indx;
      //   Frontier D_frontier;
      //   D_frontier.indx = temp;
      //   int match = 0;
      //   for (unsigned int j = 0; j < d_frontier.size(); j++) {
      //     if (d_frontier[j].indx == temp) {
      //       ++match;
      //       break;
      //     }
      //   }
      //   if (!match) {
      //     d_frontier.push_back(D_frontier);
      //   }
      // }
      if ((count1 == 2) || (count2 == 2) || (count4 == 2) || (count5 == 2)) {
        np->d_value[0] = 0;
      }
      if ((count1 == 1) && (count2 == 1) || ((count4 == 1) && (count5 == 1))) {
        np->d_value[0] = 1;
      }
      if (((count1 == 1) && (count4 == 1)) ||
          ((count2 == 1) && (count5 == 1))) {
        np->d_value[0] = D;
      }
      if (((count1 == 1) && (count5 == 1)) ||
          ((count2 == 1) && (count4 == 1))) {
        np->d_value[0] = D_bar;
      }
    }
  }
  if (np->type == 3) {
    int fin_num = np->fin;
    int count1 = 0, count2 = 0, count3 = 0, count4 = 0, count5 = 0;
    int temp;
    for (int i = 0; i < fin_num; i++) {
      if (np->unodes[i]->d_value[0] == 0) {
        ++count1;
      }
      if (np->unodes[i]->d_value[0] == 1) {
        ++count2;
      }
      if (np->unodes[i]->d_value[0] == X) {
        ++count3;
      }
      if (np->unodes[i]->d_value[0] == D) {
        ++count4;
      }
      if (np->unodes[i]->d_value[0] == D_bar) {
        ++count5;
      }
    }
    if (np->d_value[0] != X) {
      // int temp = np->indx;
      // Frontier D_frontier;
      // D_frontier.indx = temp;
      // for (unsigned int j = 0; j < d_frontier.size(); j++) {
      //   if (d_frontier[j].indx == temp) {
      //     d_frontier.erase(d_frontier.begin() + j);
      //     break;
      //   }
      // }
      if (np->d_value[0] == D) {
        if (!(((count2 == 0) && (count3 != 0) &&
               (((count4 == 0) && (count5 != 0)) ||
                ((count4 != 0) && (count5 == 0)) ||
                ((count5 == 0) && (count4 == 0)))) ||
              ((count2 == 0) && (count3 == 0) && (count5 == 0) &&
               (count4 != 0)) ||
              ((count2 != 0) || ((count4 > 0) && (count5 > 0))))) {
          // cout << "or false-D: " << np->num << endl;
          return false;
        }
      }
      if (np->d_value[0] == D_bar) {
        if (!(((count2 == 0) && (count3 != 0) &&
               (((count4 == 0) && (count5 != 0)) ||
                ((count4 != 0) && (count5 == 0)) ||
                ((count5 == 0) && (count4 == 0)))) ||
              ((count2 == 0) && (count3 == 0) && (count4 == 0) &&
               (count5 != 0)) ||
              (count1 == fin_num))) {
          // cout << "or false-D_bar: " << np->num << endl;
          return false;
        }
      }
      if (np->d_value[0] == 1) {
        if (!(((count2 == 0) && (count3 != 0) &&
               (((count4 == 0) && (count5 != 0)) ||
                ((count4 != 0) && (count5 == 0)) ||
                ((count5 == 0) && (count4 == 0)))) ||
              ((count2 != 0) || ((count4 > 0) && (count5 > 0))))) {
          // cout << "or false-1: " << np->num << endl;
          return false;
        }
      }
      if (np->d_value[0] == 0) {
        if (!(((count2 == 0) && (count3 != 0) &&
               (((count4 == 0) && (count5 != 0)) ||
                ((count4 != 0) && (count5 == 0)) ||
                ((count5 == 0) && (count4 == 0)))) ||
              (count1 == fin_num))) {
          // cout << "or false-0: " << np->num << endl;
          return false;
        } else {
          for (int r = 0; r < fin_num; r++) {
            if (np->unodes[r]->d_value[0] == X) {
              np->unodes[r]->d_value[0] = 0;
            }
          }
        }
      }
    }
    if (np->d_value[0] == X) {
      if ((count2 == 0) && (count3 == 0) && (count5 == 0) && (count4 != 0)) {
        np->d_value[0] = D;
      }
      if ((count2 == 0) && (count3 == 0) && (count4 == 0) && (count5 != 0)) {
        np->d_value[0] = D_bar;
      }
      if ((count2 != 0) || ((count4 > 0) && (count5 > 0))) {
        np->d_value[0] = 1;
      }
      if (count1 == fin_num) {
        np->d_value[0] = 0;
      }
      // if ((count2 == 0) && (count3 != 0) &&
      //     (((count4 == 0) && (count5 != 0)) ||
      //      ((count4 != 0) && (count5 == 0)))) {
      //   int temp = np->indx;
      //   Frontier D_frontier;
      //   D_frontier.indx = temp;
      //   int match = 0;
      //   for (unsigned int j = 0; j < d_frontier.size(); j++) {
      //     if (d_frontier[j].indx == temp) {
      //       ++match;
      //       break;
      //     }
      //   }
      //   if (!match) {
      //     d_frontier.push_back(D_frontier);
      //   }
      // }
    }
  }
  if (np->type == 4) {
    int fin_num = np->fin;
    int count1 = 0, count2 = 0, count3 = 0, count4 = 0, count5 = 0;
    int temp;
    for (int i = 0; i < fin_num; i++) {
      if (np->unodes[i]->d_value[0] == 0) {
        ++count1;
      }
      if (np->unodes[i]->d_value[0] == 1) {
        ++count2;
      }
      if (np->unodes[i]->d_value[0] == X) {
        ++count3;
      }
      if (np->unodes[i]->d_value[0] == D) {
        ++count4;
      }
      if (np->unodes[i]->d_value[0] == D_bar) {
        ++count5;
      }
    }
    if (np->d_value[0] != X) {
      // int temp = np->indx;
      // Frontier D_frontier;
      // D_frontier.indx = temp;
      // for (unsigned int j = 0; j < d_frontier.size(); j++) {
      //   if (d_frontier[j].indx == temp) {
      //     d_frontier.erase(d_frontier.begin() + j);
      //     break;
      //   }
      // }
      if (np->d_value[0] == D_bar) {
        if (!(((count2 == 0) && (count3 != 0) &&
               (((count4 == 0) && (count5 != 0)) ||
                ((count4 != 0) && (count5 == 0)) ||
                ((count5 == 0) && (count4 == 0)))) ||
              ((count2 == 0) && (count3 == 0) && (count5 == 0) &&
               (count4 != 0)) ||
              ((count2 != 0) || ((count4 > 0) && (count5 > 0))))) {
          // cout << "nor false: " << np->num << endl;
          return false;
        }
      }
      if (np->d_value[0] == D) {
        if (!(((count2 == 0) && (count3 != 0) &&
               (((count4 == 0) && (count5 != 0)) ||
                ((count4 != 0) && (count5 == 0)) ||
                ((count5 == 0) && (count4 == 0)))) ||
              ((count2 == 0) && (count3 == 0) && (count4 == 0) &&
               (count5 != 0)) ||
              (count1 == fin_num))) {
          // cout << "nor false: " << np->num << endl;
          return false;
        }
      }
      if (np->d_value[0] == 0) {
        if (!(((count2 == 0) && (count3 != 0) &&
               (((count4 == 0) && (count5 != 0)) ||
                ((count4 != 0) && (count5 == 0)) ||
                ((count5 == 0) && (count4 == 0)))) ||
              ((count2 != 0) || ((count4 > 0) && (count5 > 0))))) {
          // cout << "nor false: " << np->num << endl;
          return false;
        }
      }
      if (np->d_value[0] == 1) {
        if (!(((count2 == 0) && (count3 != 0) &&
               (((count4 == 0) && (count5 != 0)) ||
                ((count4 != 0) && (count5 == 0)) ||
                ((count5 == 0) && (count4 == 0)))) ||
              (count1 == fin_num))) {
          // cout << "nor false: " << np->num << endl;
          return false;
        } else {
          for (int r = 0; r < fin_num; r++) {
            if (np->unodes[r]->d_value[0] == X) {
              np->unodes[r]->d_value[0] = 0;
            }
          }
        }
      }
    }
    if (np->d_value[0] == X) {
      if ((count2 == 0) && (count3 == 0) && (count5 == 0) && (count4 != 0)) {
        np->d_value[0] = D_bar;
      }
      if ((count2 == 0) && (count3 == 0) && (count4 == 0) && (count5 != 0)) {
        np->d_value[0] = D;
      }
      if ((count2 != 0) || ((count4 > 0) && (count5 > 0))) {
        np->d_value[0] = 0;
      }
      if (count1 == fin_num) {
        np->d_value[0] = 1;
      }
      // if ((count2 == 0) && (count3 != 0) &&
      //     (((count4 == 0) && (count5 != 0)) ||
      //      ((count4 != 0) && (count5 == 0)))) {
      //   int temp = np->indx;
      //   Frontier D_frontier;
      //   D_frontier.indx = temp;
      //   int match = 0;
      //   for (unsigned int j = 0; j < d_frontier.size(); j++) {
      //     if (d_frontier[j].indx == temp) {
      //       ++match;
      //       break;
      //     }
      //   }
      //   if (!match) {
      //     d_frontier.push_back(D_frontier);
      //   }
      // }
    }
  }
  if (np->type == 5) {
    if (np->d_value[0] != X) {
      // int temp = np->indx;
      // Frontier D_frontier;
      // D_frontier.indx = temp;
      // for (unsigned int j = 0; j < d_frontier.size(); j++) {
      //   if (d_frontier[j].indx == temp) {
      //     d_frontier.erase(d_frontier.begin() + j);
      //     break;
      //   }
      // }
      if (np->d_value[0] == D) {
        if (!((np->unodes[0]->d_value[0] == X) ||
              (np->unodes[0]->d_value[0] == D_bar) ||
              (np->unodes[0]->d_value[0] == 0))) {
          // cout << "not false-D: " << np->num << endl;
          return false;
        }
        if (np->unodes[0]->d_value[0] == X) {
          np->unodes[0]->d_value[0] = 0;
        }
      }
      if (np->d_value[0] == D_bar) {
        if (!((np->unodes[0]->d_value[0] == X) ||
              (np->unodes[0]->d_value[0] == D) ||
              (np->unodes[0]->d_value[0] == 1))) {
          // cout << "not false-D: " << np->num << endl;
          return false;
        }
        if (np->unodes[0]->d_value[0] == X) {
          np->unodes[0]->d_value[0] = 1;
        }
      }
      if (np->d_value[0] == 0) {
        if (!((np->unodes[0]->d_value[0] == X) ||
              (np->unodes[0]->d_value[0] == 1))) {
          // cout << "not false-0: " << np->num << endl;
          return false;
        }
        if (np->unodes[0]->d_value[0] == X) {
          np->unodes[0]->d_value[0] = 1;
        }
      }
      if (np->d_value[0] == 1) {
        if (!((np->unodes[0]->d_value[0] == X) ||
              (np->unodes[0]->d_value[0] == 0))) {
          // // cout << np->unodes[0]->d_value[0] << "--------debug" << endl;
          // cout << "not false-1: " << np->num << endl;
          return false;
        }
        if (np->unodes[0]->d_value[0] == X) {
          np->unodes[0]->d_value[0] = 0;
        }
      }
    }
    if (np->d_value[0] == X) {
      if (np->unodes[0]->d_value[0] == D) {
        np->d_value[0] = D_bar;
      }
      if (np->unodes[0]->d_value[0] == D_bar) {
        np->d_value[0] = D;
      }
      if (np->unodes[0]->d_value[0] == 0) {
        np->d_value[0] = 1;
      }
      if (np->unodes[0]->d_value[0] == 1) {
        np->d_value[0] = 0;
      }
    }
  }

  if (np->type == 6) {
    int fin_num = np->fin;
    int count1 = 0, count2 = 0, count3 = 0, count4 = 0, count5 = 0;
    int temp;
    for (int i = 0; i < fin_num; i++) {
      if (np->unodes[i]->d_value[0] == 0) {
        ++count1;
      }
      if (np->unodes[i]->d_value[0] == 1) {
        ++count2;
      }
      if (np->unodes[i]->d_value[0] == X) {
        ++count3;
      }
      if (np->unodes[i]->d_value[0] == D) {
        ++count4;
      }
      if (np->unodes[i]->d_value[0] == D_bar) {
        ++count5;
      }
    }

    if (np->d_value[0] != X) {
      // int temp = np->indx;
      // Frontier D_frontier;
      // D_frontier.indx = temp;
      // for (unsigned int j = 0; j < d_frontier.size(); j++) {
      //   if (d_frontier[j].indx == temp) {
      //     d_frontier.erase(d_frontier.begin() + j);
      //     break;
      //   }
      // }
      if (np->d_value[0] == 1) {
        if (!(((count1 == 0) && (count3 != 0) &&
               (((count4 == 0) && (count5 != 0)) ||
                ((count4 != 0) && (count5 == 0)) ||
                ((count4 == 0) && (count5 == 0)))) ||
              (count1 != 0) || ((count4 > 0) && (count5 > 0)))) {
          // cout << "nand false-1: " << np->num << endl;
          return false;
        }
      }
      if (np->d_value[0] == 0) {
        if (!(((count1 == 0) && (count3 != 0) &&
               (((count4 == 0) && (count5 != 0)) ||
                ((count4 != 0) && (count5 == 0)) ||
                ((count4 == 0) && (count5 == 0)))) ||
              (count2 == fin_num))) {
          // cout << "nand false-0: " << np->num << endl;
          return false;
        } else {
          for (int r = 0; r < fin_num; r++) {
            if (np->unodes[r]->d_value[0] == X) {
              np->unodes[r]->d_value[0] = 1;
            }
          }
        }
      }
      if (np->d_value[0] == D_bar) {
        if (!(((count1 == 0) && (count3 != 0) &&
               (((count4 == 0) && (count5 != 0)) ||
                ((count4 != 0) && (count5 == 0)) ||
                ((count4 == 0) && (count5 == 0)))) ||
              ((count1 == 0) && (count3 == 0) && (count4 != 0) &&
               (count5 == 0)) ||
              (count2 == fin_num))) {
          // cout << "nand false-D_bar: " << np->num << endl;
          return false;
        }
      }
      if (np->d_value[0] == D) {
        if (!(((count1 == 0) && (count3 != 0) &&
               (((count4 == 0) && (count5 != 0)) ||
                ((count4 != 0) && (count5 == 0)) ||
                ((count4 == 0) && (count5 == 0)))) ||
              ((count1 == 0) && (count3 == 0) && (count4 == 0) &&
               (count5 != 0)) ||
              ((count1 != 0) || ((count4 > 0) && (count5 > 0))))) {
          // cout << "nand false-D: " << np->num << endl;
          return false;
        }
      }
    }
    if (np->d_value[0] == X) {
      if ((count1 != 0) || ((count4 > 0) && (count5 > 0))) {
        np->d_value[0] = 1;
      }
      if (count2 == fin_num) {
        np->d_value[0] = 0;
      }
      if ((count1 == 0) && (count3 == 0) && (count4 != 0) && (count5 == 0)) {
        np->d_value[0] = D_bar;
      }
      if ((count1 == 0) && (count3 == 0) && (count4 == 0) && (count5 != 0)) {
        np->d_value[0] = D;
      }
      // if ((count1 == 0) && (count3 != 0) &&
      //     (((count4 == 0) && (count5 != 0)) ||
      //      ((count4 != 0) && (count5 == 0)))) {
      //   int temp = np->indx;
      //   Frontier D_frontier;
      //   D_frontier.indx = temp;
      //   int match = 0;
      //   for (unsigned int j = 0; j < d_frontier.size(); j++) {
      //     if (d_frontier[j].indx == temp) {
      //       ++match;
      //       break;
      //     }
      //   }
      //   if (!match) {
      //     d_frontier.push_back(D_frontier);
      //   }
      // }
    }
  }

  if (np->type == 7) {
    int fin_num = np->fin;
    int count1 = 0, count2 = 0, count3 = 0, count4 = 0, count5 = 0;
    int temp;
    for (int i = 0; i < fin_num; i++) {
      if (np->unodes[i]->d_value[0] == 0) {
        ++count1;
      }
      if (np->unodes[i]->d_value[0] == 1) {
        ++count2;
      }
      if (np->unodes[i]->d_value[0] == X) {
        ++count3;
      }
      if (np->unodes[i]->d_value[0] == D) {
        ++count4;
      }
      if (np->unodes[i]->d_value[0] == D_bar) {
        ++count5;
      }
    }
    if (np->d_value[0] != X) {
      // int temp = np->indx;
      // Frontier D_frontier;
      // D_frontier.indx = temp;
      // for (unsigned int j = 0; j < d_frontier.size(); j++) {
      //   if (d_frontier[j].indx == temp) {
      //     d_frontier.erase(d_frontier.begin() + j);
      //     break;
      //   }
      // }
      if (np->d_value[0] == 0) {
        if (!(((count1 == 0) && (count3 != 0) &&
               (((count4 == 0) && (count5 != 0)) ||
                ((count4 != 0) && (count5 == 0)) ||
                ((count4 == 0) && (count5 == 0)))) ||
              (count1 != 0) || ((count4 > 0) && (count5 > 0)))) {
          // cout << "and false-0: " << np->num << endl;
          return false;
        }
      }
      if (np->d_value[0] == 1) {
        if (!(((count1 == 0) && (count3 != 0) &&
               (((count4 == 0) && (count5 != 0)) ||
                ((count4 != 0) && (count5 == 0)) ||
                ((count4 == 0) && (count5 == 0)))) ||
              (count2 == fin_num))) {
          // cout << "and false-1: " << np->num << endl;
          return false;
        } else {
          for (int r = 0; r < fin_num; r++) {
            if (np->unodes[r]->d_value[0] == X) {
              np->unodes[r]->d_value[0] = 1;
            }
          }
        }
      }
      if (np->d_value[0] == D) {
        if (!(((count1 == 0) && (count3 != 0) &&
               (((count4 == 0) && (count5 != 0)) ||
                ((count4 != 0) && (count5 == 0)) ||
                ((count4 == 0) && (count5 == 0)))) ||
              ((count1 == 0) && (count3 == 0) && (count4 != 0) &&
               (count5 == 0)) ||
              (count2 == fin_num))) {
          // cout << "and false-D: " << np->num << endl;
          return false;
        }
      }
      if (np->d_value[0] == D_bar) {
        if (!(((count1 == 0) && (count3 != 0) &&
               (((count4 == 0) && (count5 != 0)) ||
                ((count4 != 0) && (count5 == 0)) ||
                ((count4 == 0) && (count5 == 0)))) ||
              ((count1 == 0) && (count3 == 0) && (count4 == 0) &&
               (count5 != 0)) ||
              ((count1 != 0) || ((count4 > 0) && (count5 > 0))))) {
          // cout << "and false-D_bar: " << np->num << endl;
          return false;
        }
      }
    }
    if (np->d_value[0] == X) {
      if ((count1 != 0) || ((count4 > 0) && (count5 > 0))) {
        np->d_value[0] = 0;
      }
      if (count2 == fin_num) {
        np->d_value[0] = 1;
      }
      if ((count1 == 0) && (count3 == 0) && (count4 != 0) && (count5 == 0)) {
        np->d_value[0] = D;
      }
      if ((count1 == 0) && (count3 == 0) && (count4 == 0) && (count5 != 0)) {
        np->d_value[0] = D_bar;
      }
      // if ((count1 == 0) && (count3 != 0) &&
      //     (((count4 == 0) && (count5 != 0)) ||
      //      ((count4 != 0) && (count5 == 0)))) {
      //   int temp = np->indx;
      //   Frontier D_frontier;
      //   D_frontier.indx = temp;
      //   int match = 0;
      //   for (unsigned int j = 0; j < d_frontier.size(); j++) {
      //     if (d_frontier[j].indx == temp) {
      //       ++match;
      //       break;
      //     }
      //   }
      //   if (!match) {
      //     d_frontier.push_back(D_frontier);
      //   }
      // }
    }
  }
  return true;
}
bool imply_and_check() {
  while (!event_node_list.empty()) {
    // cout << event_node_list.size() << "----node list size\n";
    // cout << "node list num: ";
    // for (int r = 0; r < event_node_list.size(); r++) {
    //   NSTRUC *p;
    //   p = &Node[event_node_list[r]];
    //   cout << p->num << '-';
    // }
    // cout << endl;
    int list_size = event_node_list.size();
    for (int i = 0; i < list_size; i++) {
      if (event_node_list[i] == (-1)) {
        continue;
      }
      NSTRUC *np;
      bool mark;
      np = &Node[event_node_list[i]];
      event_node_list[i] = -1;
      if (np->d_value[0] == X) {
        np->label[0] = 0;
        continue;
      } else {
        np->label[0] = 1;
        mark = gate_logic(np);
        if (!mark) {
          return false;
        }
        int fout_num = np->fout;
        int fin_num = np->fin;
        for (int r = 0; r < fin_num; r++) {
          int ind;
          ind = np->unodes[r]->indx;
          NSTRUC *p1;
          p1 = &Node[ind];
          // // cout << "upper node value: " << p1->d_value[0] << endl;
          mark = gate_logic(p1);
          if (!mark) {
            return false;
          }
        }
        for (int j = 0; j < fout_num; j++) {
          int ind;
          ind = np->dnodes[j]->indx;
          NSTRUC *p1;
          p1 = &Node[ind];
          // // cout << "down node value: " << p1->d_value[0] << endl;
          mark = gate_logic(p1);
          if (!mark) {
            return false;
          }
        }
        for (int k = 0; k < fin_num; k++) {
          if (np->unodes[k]->label[0] == 0) {
            int temp;
            temp = np->unodes[k]->indx;
            // // cout << temp << "===========\n";
            event_node_list.push_back(temp);
          }
        }
        for (int m = 0; m < fout_num; m++) {
          if (np->dnodes[m]->label[0] == 0) {
            int temp;
            temp = np->dnodes[m]->indx;
            // // cout << temp << "===========\n";
            event_node_list.push_back(temp);
          }
        }
      }
    }
    event_node_list.erase(
        remove(event_node_list.begin(), event_node_list.end(), -1),
        event_node_list.end());
  }
  // for (int i = 0; i < Nnodes; i++) {
  //   NSTRUC *p;
  //   p = &Node[i];
  //   if (p->d_value[0] != X) {
  //     cout << p->num << '-' << p->type << "---------" << p->d_value[0] <<
  //     endl; for (int q = 0; q < p->fin; q++) {
  //       cout << q << "th input ----value: " << p->unodes[q]->d_value[0]
  //            << "   num: " << p->unodes[q]->num << endl;
  //     }
  //   }
  // }
  get_frontier();
  // cout << "j frontier: ";
  // for (int r = 0; r < j_frontier.size(); r++) {
  //   NSTRUC *p;
  //   p = &Node[j_frontier[r].indx];
  //   cout << p->num << '-';
  // }
  // cout << endl;
  // cout << "d frontier: ";
  // for (int r = 0; r < d_frontier.size(); r++) {
  //   NSTRUC *p;
  //   p = &Node[d_frontier[r].indx];
  //   cout << p->num << '-';
  // }
  // cout << endl;
  return true;
}
bool error_not_at_po() {
  for (int i = 0; i < Npo; i++) {
    if (Poutput[i]->d_value[0] == D || Poutput[i]->d_value[0] == D_bar) {
      return false;
    }
  }
  return true;
}
void d_pattern(NSTRUC *np, int label) {
  int temp = np->indx;
  event_node_list.push_back(temp);
  if (np->type == 2) {
    int fin_num = np->fin;
    int count1 = 0, count2 = 0, count3 = 0, count4 = 0, count5 = 0;
    int temp;
    for (int i = 0; i < fin_num; i++) {
      if (np->unodes[i]->d_value[0] == X) {
        if (label == 0) {
          np->unodes[i]->d_value[0] = 0;
        } else {
          np->unodes[i]->d_value[0] = 1;
        }
      }
      if (np->unodes[i]->d_value[0] == D) {
        ++count4;
      }
      if (np->unodes[i]->d_value[0] == D_bar) {
        ++count5;
      }
    }
    if (count4 > count5) {
      if (label == 0) {
        np->d_value[0] = D;
      } else {
        np->d_value[0] = D_bar;
      }
    }
    if (count4 < count5) {
      if (label == 0) {
        np->d_value[0] = D_bar;
      } else {
        np->d_value[0] = D;
      }
    }
  }
  if (np->type == 3) {
    int fin_num = np->fin;
    int count1 = 0, count2 = 0, count3 = 0, count4 = 0, count5 = 0;
    int temp;
    for (int i = 0; i < fin_num; i++) {
      if (np->unodes[i]->d_value[0] == X) {
        np->unodes[i]->d_value[0] = 0;
      }
      if (np->unodes[i]->d_value[0] == D) {
        ++count4;
      }
      if (np->unodes[i]->d_value[0] == D_bar) {
        ++count5;
      }
    }
    if (count4 > count5) {
      temp = D;
      np->d_value[0] = temp;
    }
    if (count4 < count5) {
      temp = D_bar;
      np->d_value[0] = temp;
    }
  }
  if (np->type == 4) {
    int fin_num = np->fin;
    int count1 = 0, count2 = 0, count3 = 0, count4 = 0, count5 = 0;
    int temp;
    for (int i = 0; i < fin_num; i++) {
      if (np->unodes[i]->d_value[0] == X) {
        np->unodes[i]->d_value[0] = 0;
      }
      if (np->unodes[i]->d_value[0] == D) {
        ++count4;
      }
      if (np->unodes[i]->d_value[0] == D_bar) {
        ++count5;
      }
    }
    if (count4 > count5) {
      temp = D_bar;
      np->d_value[0] = temp;
    }
    if (count4 < count5) {
      temp = D;
      np->d_value[0] = temp;
    }
  }
  if (np->type == 6) {
    int fin_num = np->fin;
    int count1 = 0, count2 = 0, count3 = 0, count4 = 0, count5 = 0;
    int temp;
    for (int i = 0; i < fin_num; i++) {
      if (np->unodes[i]->d_value[0] == X) {
        np->unodes[i]->d_value[0] = 1;
      }
      if (np->unodes[i]->d_value[0] == D) {
        ++count4;
      }
      if (np->unodes[i]->d_value[0] == D_bar) {
        ++count5;
      }
    }
    if (count4 > count5) {
      temp = D_bar;
      np->d_value[0] = temp;
    }
    if (count4 < count5) {
      temp = D;
      np->d_value[0] = temp;
    }
  }
  if (np->type == 7) {
    int fin_num = np->fin;
    int count1 = 0, count2 = 0, count3 = 0, count4 = 0, count5 = 0;
    int temp;
    for (int i = 0; i < fin_num; i++) {
      if (np->unodes[i]->d_value[0] == X) {
        np->unodes[i]->d_value[0] = 1;
      }
      if (np->unodes[i]->d_value[0] == D) {
        ++count4;
      }
      if (np->unodes[i]->d_value[0] == D_bar) {
        ++count5;
      }
    }
    if (count4 > count5) {
      temp = D;
      np->d_value[0] = temp;
    }
    if (count4 < count5) {
      temp = D_bar;
      np->d_value[0] = temp;
    }
  }
}
int j_pattern(NSTRUC *np) {
  if (np->type == 3) {
    return 1;
  }
  if (np->type == 4) {
    return 1;
  }
  if (np->type == 6) {
    return 0;
  }
  if (np->type == 7) {
    return 0;
  }
  cout << "no j frontier type" << endl;
}

bool dalg_n(int depth) {
  if (depth >= 19990) {
    // cout << "over 20000" << endl;
    return false;
  }
  ++depth;
  int mark = depth;
  if (imply_and_check() == false) {
    return false;
  }
  int d_level = d_depth;
  // cout << "d_level: " << d_level << endl;
  // cout << "mark: " << mark << endl;
  // cout << "imply success\n";
  if (error_not_at_po()) {
    if (d_frontier.empty()) {
      // cout << "can not propogate to output" << endl;
      return false;
    } else {
      unvisited = 1;
      while (unvisited) {
        unvisited = 0;
        for (int i = 0; i < d_frontier.size(); i++) {
          if ((!d_frontier[i].label) && (d_frontier[i].depth == d_level)) {
            ++unvisited;
            break;
          }
        }
        if (unvisited == 0) {
          // cout << "tried all that level d frontier" << endl;
          return false;
        }
        int temp;
        int d_size = d_frontier.size();
        for (int i = 0; i < d_size; i++) {
          if ((!d_frontier[i].label) && (d_frontier[i].depth == d_level)) {
            temp = d_frontier[i].indx;
            d_frontier[i].label = 1;
            break;
          }
        }
        NSTRUC *np;
        np = &Node[temp];

        if (np->type == 2) {
          int f = 0;
          for (int i = 0; i < 2; i++) {
            backup_state(mark);
            event_node_list.clear();
            d_pattern(np, f);

            if (dalg_n(depth) == true) {
              return true;
            } else {
              restore_state(mark);
              ++f;
            }
          }
        } else {
          backup_state(mark);
          event_node_list.clear();
          d_pattern(np, 0);
          // cout << "after apply d_pattern: \n";
          // for (int i = 0; i < Nnodes; i++) {
          //   NSTRUC *p;
          //   p = &Node[i];
          //   cout << p->num << "---------------" << p->d_value[0] << endl;
          // }
          if (dalg_n(depth) == true) {
            return true;
          } else {
            restore_state(mark);
            int d_index = -1;
            for (unsigned int r = 0; r < d_frontier.size(); r++) {
              if (d_frontier[r].depth > d_level) {
                d_index = r;
                break;
              }
            }
            // for (int r = 0; r < d_frontier.size(); r++) {
            //   cout << r << "th d frontier: " << d_frontier[r].indx << '-' <<
            //   d_frontier[r].depth << endl;
            // }
            if (d_index != -1) {
              d_frontier.erase(d_frontier.begin() + d_index, d_frontier.end());
            }
            // for (int r = 0; r < d_frontier.size(); r++) {
            //   cout << r << "th d frontier: " << d_frontier[r].indx << '-'
            //        << d_frontier[r].depth << endl;
            // }
            if (dalg_n(depth) == true) {
              return true;
            }
          }
        }
      }
    }
    // cout << "tried all d frontier" << endl;
    return false;
  }

  if (j_frontier.empty()) {
    // cout << "j frontier empty -> success" << endl;
    return true;
  }

  int temp, fin_num, control_value;
  temp = j_frontier.front().indx;
  // cout << "j frontier: ";
  // for (int r = 0; r < j_frontier.size(); r++)
  // {
  //   NSTRUC *p;
  //   p = &Node[j_frontier[r].indx];
  //   // cout << p->num << '-';
  // }
  // cout << endl;
  NSTRUC *np = &Node[temp];
  if (np->type == 2) {
    int f = 0;
    for (int i = 0; i < 2; i++) {
      backup_state(mark);
      if (np->d_value[0] == 0) {
        if (f == 0) {
          np->unodes[0]->d_value[0] = 1;
          np->unodes[1]->d_value[0] = 1;
        } else {
          np->unodes[0]->d_value[0] = 0;
          np->unodes[1]->d_value[0] = 0;
        }
      }
      if (np->d_value[0] == 1) {
        if (f == 0) {
          np->unodes[0]->d_value[0] = 1;
          np->unodes[1]->d_value[0] = 0;
        } else {
          np->unodes[0]->d_value[0] = 0;
          np->unodes[1]->d_value[0] = 1;
        }
      }
      event_node_list.clear();
      event_node_list.push_back(np->indx);
      if (dalg_n(depth) == true) {
        return true;
      }
      // cout << "try another pattern" << endl;
      restore_state(mark);
      get_frontier();
      ++f;
      if (f == 2) {
        return false;
      }
    }
  } else {
    control_value = j_pattern(np);
    fin_num = np->fin;
    NSTRUC *p;
    for (int i = 0; i < fin_num; i++) {
      if (np->unodes[i]->d_value[0] == X) {
        p = np->unodes[i];
        break;
      }
    }
    p->d_value[0] = control_value;
    backup_state(mark);
    event_node_list.clear();
    event_node_list.push_back(np->indx);
    if (dalg_n(depth) == true) {
      return true;
    } else {
      int j_count = 0;
      for (unsigned int i = 0; i < np->fin; i++) {
        if (np->unodes[i]->d_value[0] == X) {
          ++j_count;
          break;
        }
      }
      if (!j_count) {
        return false;
      }
      // cout << "mark: " << mark << endl;
      // cout << np->num << '-' << np->type << "---------" << np->d_value[0]
      //      << endl;
      // for (int q = 0; q < np->fin; q++) {
      //   cout << q << "th input ----value: " << np->unodes[q]->d_value[0]
      //        << "   num: " << np->unodes[q]->num << endl;
      // }
      // cout << "try another value" << endl;
      restore_state(mark);
      p->d_value[0] = 1 - control_value;
      get_frontier();
      event_node_list.clear();
      event_node_list.push_back(np->indx);
      if (dalg_n(depth) == true) {
        return true;
      }
    }
  }
  // cout << "tried all j frontier -> failure" << endl;
  return false;
}
bool dalg_l(int node_num, int stuck_fault) {
  Dalg_pattern.clear();
  global_reset_d();
  test_vector.clear();
  int fault_indx;
  int D_d;
  for (int i = 0; i < Nnodes; i++) {
    NSTRUC *np;
    np = &Node[i];
    np->d_value[0] = X;
    np->label[0] = 0;
    if (np->num == node_num) {
      event_node_list.push_back(np->indx);
      fault_indx = np->indx;
      if (stuck_fault == 0) {
        np->d_value[0] = D;
      } else {
        np->d_value[0] = D_bar;
      }
      D_d = np->d_value[0];
    }
  }
  NSTRUC *p1;
  p1 = &Node[fault_indx];
  int if_pin = 0;
  for (int r = 0; r < Npi; r++) {
    if (fault_indx == Pinput[r]->indx) {
      ++if_pin;
      break;
    }
  }
  if (if_pin) {
    if (dalg_n(depth) == true) {
      for (int m = 0; m < Npi; m++) {
        int temp;
        if ((Pinput[m]->d_value[0] == D) || (Pinput[m]->d_value[0] == 1)) {
          temp = 1;
        }
        if ((Pinput[m]->d_value[0] == D_bar) || (Pinput[m]->d_value[0] == 0)) {
          temp = 0;
        }
        if (Pinput[m]->d_value[0] == X) {
          temp = 0;
        }
        test_vector.push_back(temp);
        // cout << Pinput[m]->d_value[0] << "--";
      }
      // cout << endl;
      return true;
    }
  } else {
    get_pattern(p1); // get pattern for excite the fault in vec_Dalg_pattern;
    // print_2d(Dalg_pattern);
    int pattern_num = Dalg_pattern.size() - 1;
    int input_num = Dalg_pattern[0].size();
    for (int i = 0; i < pattern_num; i++) {
      // cout << "=============" << i << "th pattern===========\n";
      for (int j = 0; j < input_num; j++) {
        NSTRUC *p;
        p = &Node[Dalg_pattern[0][j]];
        event_node_list.push_back(Dalg_pattern[0][j]);
        p->d_value[0] = Dalg_pattern[i + 1][j];
      }
      // // cout << endl;
      // print_1d(event_node_list);
      if (dalg_n(depth) == true) {
        // sign = true;
        for (int m = 0; m < Npi; m++) {
          int temp;
          if ((Pinput[m]->d_value[0] == D) || (Pinput[m]->d_value[0] == 1)) {
            temp = 1;
          }
          if ((Pinput[m]->d_value[0] == D_bar) ||
              (Pinput[m]->d_value[0] == 0)) {
            temp = 0;
          }
          if (Pinput[m]->d_value[0] == X) {
            temp = 0;
          }
          test_vector.push_back(temp);
          // cout << Pinput[m]->d_value[0] << "--";
        }
        // cout << endl;
        return true;
      }
      Node[fault_indx].d_value[0] = D_d;
    }
  }
  // cout << "failure" << endl;
  return false;
}
void dalg(char *cp) {
  update_level();
  char buf[MAXLINE];
  int node_num;
  int stuck_fault;

  char *spaceIndx;
  spaceIndx = strchr(cp + 1, ' ');
  *spaceIndx = '\0';
  sscanf(cp + 1, "%s", buf);
  sscanf(buf, "%d", &node_num);

  char *cp2 = spaceIndx + 1;
  sscanf(cp2, "%s", buf);
  sscanf(buf, "%d", &stuck_fault);
  // // cout << node_num << "---" << stuck_fault;
  bool d;

  d = dalg_l(node_num, stuck_fault);
  string out_name;
  out_name = ckt_name;
  out_name.append("_DALG_");
  out_name.append(to_string(node_num));
  out_name.append("@");
  out_name.append(to_string(stuck_fault));
  out_name.append(".txt");
  if (d == true) {
    ofstream fd;
    fd.open(out_name);
    // write all the node levels to output file
    for (int q = 0; q < Npi; q++) {
      fd << Pinput[q]->num;
      if (q < Npi - 1) {
        fd << ',';
      }
    }
    fd << endl;
    for (int r = 0; r < Npi; r++) {
      string temp;
      if (test_vector[r] == X) {
        temp = "0";
      }
      if ((test_vector[r] == D) || (test_vector[r] == 1)) {
        temp = "1";
      }
      if ((test_vector[r] == D_bar) || (test_vector[r] == 0)) {
        temp = "0";
      }
      fd << temp;
      if (r < Npi - 1) {
        fd << ',';
      }
    }
    fd << endl;
    fd.close();
    test_vector.clear();
    Dalg_pattern.clear();
    global_reset_d();
  } else {
    cout << "failure" << endl;
  }
}

/*-----------------------------------------------------------------------
input: nothing
output: nothing
called by: PODEM
description:
  ATPG to generate test vector to detect specific faults.
-----------------------------------------------------------------------*/
bool podem_atpg(int fault_number, int fault_value) {
  NSTRUC *np, *np2;
  int index;
  int print = 0;
  bool ret_value = 0;

  for (int i = 0; i < Nnodes; i++) {
    np = &Node[i];
    if (np->num == fault_number)
      index = np->indx;
  }

  // cout<<index;

  // cout << filename;
  PODEM_inst = new podem_class();
  PODEM_inst->Setup_levl();
  if (PODEM_inst->podem_recursion(index, fault_value)) {
    ret_value = 1;
  }

  PODEM_inst->create_vector();
  return ret_value;
}

void podem(char *cp) {

  char buf[MAXLINE];
  // char buf2[MAXLINE];
  int line_number = 0;
  int value = 0;
  int printflag = 0;
  int print = 1;

  char *spaceIndx;
  spaceIndx = strchr(cp + 1, ' ');
  *spaceIndx = '\0';
  sscanf(cp + 1, "%s", buf);
  sscanf(buf, "%d", &line_number);

  char *cp2 = spaceIndx + 1;
  sscanf(cp2, "%s", buf);
  sscanf(buf, "%d", &value);

  string out_name;
  out_name = ckt_name;
  out_name.append("_PODEM_");
  out_name.append(to_string(line_number));
  out_name.append("@");
  out_name.append(to_string(value));
  out_name.append(".txt");

  // cout<<"HERE";

  // first argument;

  int index;
  // char *filename = out_name;

  NSTRUC *np;

  for (int i = 0; i < Nnodes; i++) {
    np = &Node[i];
    if (np->num == line_number)
      index = np->indx;
  }

  // cout<<index;

  // cout << filename;
  PODEM_inst = new podem_class();
  PODEM_inst->podem(index, value, out_name);
}

// initializing level, calculate the value,
void podem_class::Setup_levl() {
  value1 = new unsigned int[Nnodes];
  value2 = new unsigned int[Nnodes];
  value3 = new unsigned int[Nnodes];
  value4 = new unsigned int[Nnodes];
  task = new int[Nnodes];
  D_frontier = new int[Nnodes];

  np = &Node[faultindx];
  current_level = 0;

  // set all values as Dont care

  for (int i = 0; i < Nnodes; i++) {
    value1[i] = 0;
    value2[i] = 1;
    value3[i] = 0;
    value4[i] = 1;
  }

  int *levsize_each;
  int levelSize = 0;
  NSTRUC *np;
  podem_update_level = 1;
  update_level();
  podem_update_level = 0;
  int numLevels = lev_max + 1;
  levsize_each = new int[numLevels];
  for (int i = 0; i < numLevels; i++) {
    levsize_each[i] = 0;
  }
  for (int j = 0; j < Nnodes; j++) {
    task[j] = 0;
    np = &Node[podem_node_index_queue[j]];
    levsize_each[np->level]++;
  }

  for (int i = 0; i < numLevels; i++) {
    if (levsize_each[i] > levelSize) {
      levelSize = levsize_each[i];
    }
  }

  levelLen = new int[numLevels];
  levelEvents = new int *[numLevels];
  for (int i = 0; i < numLevels; i++) {
    levelEvents[i] = new int[levelSize];
    levelLen[i] = 0;
  }
  activation = new int[levelSize];
}

void podem_class::DFrontier(int faultindx) {

  NSTRUC *np;
  // cout << "\nget faultindx=" << faultindx << "  ";

  if (Node[faultindx].type == 0 || Node[faultindx].type == 1) {

    for (int jj = 0; jj < Node[faultindx].fout; jj++) {
      np = &Node[faultindx];
      DFrontier(np->dnodes[jj]->indx);
    }
  } else {

    if (((value1[faultindx] == 0 && value2[faultindx]) ||
         (value3[faultindx] == 0 && value4[faultindx]) ||
         (value1[faultindx] && value2[faultindx] == 0) ||
         (value3[faultindx] && value4[faultindx] == 0))) {
      D_frontier[count] = faultindx;
      // cout<<"\t inside d-frontier: faultindx:"<<faultindx<<"
      // gatenum"<<Node[faultindx].num<<"\n";
      count++;
    }

    else if ((value1[faultindx] && value2[faultindx] &&
              (value3[faultindx] == 0) && (value4[faultindx] == 0)) ||
             (value1[faultindx] == 0 && value2[faultindx] == 0 &&
              (value3[faultindx]) && (value4[faultindx]))) {
      for (int jj = 0; jj < Node[faultindx].fout; jj++) {
        // cout << "enterelseif";
        np = &Node[faultindx];
        DFrontier(np->dnodes[jj]->indx);

        // cout<<"\ninside d-frontier: Getting next one
        // "<<Node[Node[faultindx].dnodes[jj]].num<<"\n";
      }
    }
  }

  D_frontier[count] = 0;

  // cout << "\nDfrontier:";
  // cout << D_frontier[0] << "     ";
}

void podem_class::objective(int gate,
                            bool value) // backtrace based on new objective
{
  object_value = 1;
  if ((value1[gate] && !value2[gate]) || (value2[gate] && !value1[gate])) {
    next_objective = gate;
    object_value = !value;
    return;
  }

  NSTRUC *np;
  int nextGate = D_frontier[0];
  for (int i = 0; i < Node[nextGate].fin; i++) {
    np = &Node[nextGate];
    if ((value1[np->unodes[i]->indx] && !value2[np->unodes[i]->indx]) ||
        (!value1[np->unodes[i]->indx] && value2[np->unodes[i]->indx])) {
      next_objective = np->unodes[i]->indx;
    }
  }
  if (Node[nextGate].type == 6 || Node[nextGate].type == 7)
    object_value = 1;
  else if (Node[nextGate].type == 3 || Node[nextGate].type == 4)
    object_value = 0;

  return;
}

bool podem_class::possible_pathto_PO(int pos) {
  NSTRUC *np;
  for (int m = 0; m < Npo; m++) {
    if (pos == Poutput[m]->indx) {
      pathFound = true;
      return pathFound;
    }
  }
  for (int i = 0; i < Node[pos].fout; i++) {
    np = &Node[pos];
    if ((value1[np->dnodes[i]->indx] && !value2[np->dnodes[i]->indx]) ||
        (!value1[np->dnodes[i]->indx] && value2[np->dnodes[i]->indx]) ||
        (value3[np->dnodes[i]->indx] && !value4[np->dnodes[i]->indx]) ||
        (!value3[np->dnodes[i]->indx] && value4[np->dnodes[i]->indx])) {

      // cout<<"\nCheck PO"<<np->dnodes[i]->indx;
      possible_pathto_PO(np->dnodes[i]->indx);
    }
  }
  return pathFound;
}

int podem_class::backtrace(int gate, int value) {
  int node_index = gate;
  int node_value = value;
  int inverting_gate = 0;
  int back_num = 0;
  NSTRUC *np;

  while (Node[node_index].type != 0) {
    back_num++;

    if (Node[node_index].type == 4 || Node[node_index].type == 5 ||
        Node[node_index].type == 6)
      inverting_gate++;
    // cout << "fin=" << Node[node_index].fin << "   ";
    for (int i = 0; i < Node[node_index].fin; i++) {
      np = &Node[node_index];
      if ((value1[np->unodes[i]->indx] && !value2[np->unodes[i]->indx]) ||
          (value2[np->unodes[i]->indx] && !value1[np->unodes[i]->indx])) {
        node_index = np->unodes[i]->indx;
        // cout << "\nnode_index=" << node_index << "  ";
        break;
      }
    }
    if (back_num > 5000)
      return -1;
  }
  if (inverting_gate % 2 != 0)
    node_value = !node_value;

  back_gate = node_index;
  return node_value;
}

void podem_class::Store_lev_node(int levelN, int gateinx) {
  levelEvents[levelN][levelLen[levelN]] = gateinx;
  levelLen[levelN]++;
}

void podem_class::left_node_sim() {
  NSTRUC *np;
  current_level = 0;
  int next_level;
  int gateN, pre_gate, post_node;
  int i;
  unsigned int val1, val2, intermediate;
  activated = 0;
  while (current_level <= lev_max) {
    gateN = Return_node_index();
    // cout << "\ngateN=" << gateN;
    if (gateN != -1) // if a valid event
    {
      task[gateN] = 0;
      np = &Node[gateN];
      switch (np->type) {
      case 0: // PI
        val1 = value1[gateN];
        val2 = value2[gateN];
        break;
      case 1: // BRANCH
        val1 = value1[np->unodes[0]->indx];
        val2 = value2[np->unodes[0]->indx];
        break;
      case 2: // XOR
        val1 = value1[np->unodes[0]->indx];
        val2 = value2[np->unodes[0]->indx];
        for (i = 1; i < np->fin; i++) {
          pre_gate = np->unodes[i]->indx;
          intermediate = 1 ^ (((1 ^ value1[pre_gate]) & (1 ^ val1)) |
                              (value2[pre_gate] & val2));
          val2 =
              ((1 ^ value1[pre_gate]) & val2) | (value2[pre_gate] & (1 ^ val1));
          val1 = intermediate;
        }
        break;
      case 3: // OR
        val1 = val2 = 0;
        for (i = 0; i < np->fin; i++) {
          pre_gate = np->unodes[i]->indx;
          val1 |= value1[np->unodes[i]->indx];
          val2 |= value2[np->unodes[i]->indx];
        }
        break;
      case 4: // NOR
        val1 = val2 = 0;
        for (i = 0; i < np->fin; i++) {
          pre_gate = np->unodes[i]->indx;
          val1 |= value1[np->unodes[i]->indx];
          val2 |= value2[np->unodes[i]->indx];
        }
        intermediate = val1;
        val1 = 1 ^ val2;
        val2 = 1 ^ intermediate;
        break;
      case 5: // NOT
        pre_gate = np->unodes[0]->indx;
        val1 = 1 ^ value2[pre_gate];
        val2 = 1 ^ value1[pre_gate];
        break;
      case 6: // NAND
        val1 = val2 = 1;
        for (i = 0; i < np->fin; i++) {
          pre_gate = np->unodes[i]->indx;
          val1 &= value1[np->unodes[i]->indx];
          val2 &= value2[np->unodes[i]->indx];
        }
        intermediate = val1;
        val1 = 1 ^ val2;
        val2 = 1 ^ intermediate;
        break;
      case 7: // AND
        val1 = val2 = 1;
        for (i = 0; i < np->fin; i++) {
          pre_gate = np->unodes[i]->indx;
          val1 &= value1[np->unodes[i]->indx];
          val2 &= value2[np->unodes[i]->indx];
        }
        break;
      default:
        cout << "illegal gate type\n";
        exit(-1);
      }

      // cout << "\ninside left_node_sim()\n";
      // cout << "\ngatenum=" << Node[gateN].num << "  value1: " <<
      // value1[gateN] << "->" << val1 << "\n";  cout << "\ngatenum=" <<
      // Node[gateN].num << "  value2: " << value2[gateN] << "->" << val2 <<
      // "\n";

      /*
      // if gate value did not changed-added by us
      if ((val1 == value1[gateN]) || (val2 == value2[gateN]))
      {
        cout<<"enter";
        task[gateN] = 0;
      }
*/
      /*
      cout << "\nprinting taskuled";
      for (int i = 0; i < Nnodes; i++)
      {
        cout << "\t" << i << "    " << task[i];
      }
*/
      // if gate value changed
      if ((val1 != value1[gateN]) || (val2 != value2[gateN])) {
        value1[gateN] = val1;
        value2[gateN] = val2;
        for (i = 0; i < np->fout; i++) {
          post_node = np->dnodes[i]->indx;
          next_level = Node[post_node].level;
          // cout << "\ngood here!\t" << next_level << "  " << post_node <<
          // "\n";  cout << "\niftrue?" << task[post_node];
          if (task[post_node] == 0) {

            if (next_level != 0) {
              // cout << "\n insertedEventinleft_node_sim" << next_level << "
              // "
              // << post_node;
              Store_lev_node(next_level, post_node);
            } else // same level
            {
              activation[activated] = post_node;
              activated++;
            }
            // task[post_node] = 1;
          }
        }
      }
    }
  }
}

void podem_class::right_node_sim() {
  NSTRUC *np;
  int next_level;
  int gateN, pre_gate, post_node;
  int i;
  unsigned int val1, val2, intermediate;

  current_level = 0;
  activated = 0;
  // cout << "Hi";
  while (current_level <= lev_max) {
    gateN = Return_node_index();
    // cout << "\ngateN=" << gateN;
    if (gateN != -1 && gateN != faultindx) // if a valid event
    {
      task[gateN] = 0;
      np = &Node[gateN];
      // cout << "  " << np->type;
      switch (np->type) {
      case 0: // PI
        val1 = value3[gateN];
        val2 = value4[gateN];
        break;
      case 1: // BRANCH
        for (i = 0; i < np->fin; i++) {
          val1 = value3[np->unodes[i]->indx];
          val2 = value4[np->unodes[i]->indx];
        }
        break;
      case 2: // XOR
        val1 = value3[np->unodes[0]->indx];
        val2 = value4[np->unodes[0]->indx];
        for (i = 1; i < np->fin; i++) {
          pre_gate = np->unodes[i]->indx;
          intermediate = 1 ^ (((1 ^ value3[pre_gate]) & (1 ^ val1)) |
                              (value4[pre_gate] & val2));
          val2 =
              ((1 ^ value3[pre_gate]) & val2) | (value4[pre_gate] & (1 ^ val1));
          val1 = intermediate;
        }
        break;
      case 3: // OR
        val1 = val2 = 0;
        for (i = 0; i < np->fin; i++) {
          pre_gate = np->unodes[i]->indx;
          val1 |= value3[np->unodes[i]->indx];
          val2 |= value4[np->unodes[i]->indx];
        }
        break;
      case 4: // NOR
        val1 = val2 = 0;
        for (i = 0; i < np->fin; i++) {
          pre_gate = np->unodes[i]->indx;
          val1 |= value3[np->unodes[i]->indx];
          val2 |= value4[np->unodes[i]->indx];
        }
        intermediate = val1;
        val1 = 1 ^ val2;
        val2 = 1 ^ intermediate;
        break;
      case 5: // NOT
        pre_gate = np->unodes[0]->indx;
        val1 = 1 ^ value4[pre_gate];
        val2 = 1 ^ value3[pre_gate];
        break;
      case 6: // NAND
        val1 = val2 = 1;
        for (i = 0; i < np->fin; i++) {
          pre_gate = np->unodes[i]->indx;
          val1 &= value3[np->unodes[i]->indx];
          val2 &= value4[np->unodes[i]->indx];
          // cout<<"\nNAND"<<np->unodes[i]->num<<" "<<val1<<"  "<<val2;
        }
        intermediate = val1;
        val1 = 1 ^ val2;
        val2 = 1 ^ intermediate;
        break;
      case 7: // AND
        val1 = val2 = 1;
        for (i = 0; i < np->fin; i++) {
          pre_gate = np->unodes[i]->indx;
          val1 &= value3[np->unodes[i]->indx];
          val2 &= value4[np->unodes[i]->indx];
        }
        break;
      default:
        // cout << "illegal gate type:  " << np->type << "\n";
        exit(-1);
      }
      /*
      cout << "inside right_node_sim()\n";
      cout << "\t gatenum=" << Node[gateN].num << "  value3: " <<
      value3[gateN]
      << "->" << val1 << "\n"; cout << "\t gatenum=" << Node[gateN].num << "
      value4: " << value4[gateN] << "->" << val2 << "\n";
*/
      // if gate value changed
      if ((val1 != value3[gateN]) || (val2 != value4[gateN])) {
        value3[gateN] = val1;
        value4[gateN] = val2;
        for (i = 0; i < np->fout; i++) {
          post_node = np->dnodes[i]->indx;
          next_level = Node[post_node].level;
          if (task[post_node] == 0) {
            if (next_level != 0)
              Store_lev_node(next_level, post_node);
            else // same level
            {
              activation[activated] = post_node;
              activated++;
            }
            // task[post_node] = 1;
          }
        }
      }
    }
  }
}

// returning current levels all node index
int podem_class::Return_node_index() {
  while ((levelLen[current_level] == 0) && (current_level <= lev_max)) {
    current_level++;
  }
  if ((current_level <= lev_max) && (levelLen[current_level] > 0)) {
    levelLen[current_level]--;
    // cout << "\n LEVEL=" << levelLen[current_level] << "   " <<
    // levelEvents[current_level][levelLen[current_level]];
    return (levelEvents[current_level][levelLen[current_level]]);
  } else
    return (-1);
}

//**************************************************************************
bool podem_class::Check_fault_activation(int fault, int value) {
  faultindx = fault;
  faultvalue = value;
  int onecount = 0, zerocount = 0;
  // cout << "\nfault=" << faultindx << "  " << faultvalue;

  if (value1[Node[faultindx].indx] && value2[Node[faultindx].indx])
    onecount++;
  if (!value1[Node[faultindx].indx] && !value2[Node[faultindx].indx])
    zerocount++;
  if (onecount > 0 || zerocount > 0) {
    // cout << onecount << zerocount;
    return true;
  }

  else
    return false;
}

bool podem_class::podem_recursion(int faultindx, int faultvalue) {
  count = 0;
  path_find = false;
  isDetected = false;
  int Cin;
  int post_gate;
  NSTRUC *np2;

  np = &Node[faultindx];
  DFrontier(faultindx);

  // printing D_frontier
  // for (int i = 0; D_frontier[i] > 0; i++)
  //  cout << D_frontier[i] << "  ";

  // ------------  CHECK if the fault is propogated to the output
  for (int i = 0; i < Npo; i++) {
    if ((value1[Poutput[i]->indx] && value2[Poutput[i]->indx] &&
         !value3[Poutput[i]->indx] && !value4[Poutput[i]->indx]) ||
        (!value1[Poutput[i]->indx] && !value2[Poutput[i]->indx] &&
         value3[Poutput[i]->indx] && value4[Poutput[i]->indx])) {
      isDetected = true;
      // cout << "\nPODEM detected the fault: " << Node[faultindx].num << "
      // stuck at " << faultvalue << "\n";
      return true;
    }
  }

  for (int i = 0; D_frontier[i] > 0; i++) {
    if (possible_pathto_PO(D_frontier[i])) {

      // cout << "path available\n";
      path_find = true;
      break;
    }
  }

  if (path_find) {

    objective(faultindx, faultvalue);

    Cin = backtrace(next_objective, object_value);
    // cout << "\nback_gate1=" << Node[back_gate].num << "   backtracevalue="
    // << Cin;  cout << "\nobjective=" << next_objective << "  " <<
    // object_value;

    if (Cin == 0) // Assign values to PI
    {
      value1[back_gate] = 0;
      value2[back_gate] = 0;
      value3[back_gate] = 0;
      value4[back_gate] = 0;
    } else if (Cin == 1) {
      value1[back_gate] = 1;
      value2[back_gate] = 1;
      value3[back_gate] = 1;
      value4[back_gate] = 1;
    } else if (Cin == -1) {
      // cout << "\nreturnfalse";
      return false;
    }

    for (int i = 0; i < Node[back_gate].fout; i++) {
      np2 = &Node[back_gate];
      post_gate = np2->dnodes[i]->indx;

      if (task[post_gate] == 0) {
        // cout << "\n insertedEvent1  " << Node[post_gate].level << "  " <<
        // post_gate;
        Store_lev_node(Node[post_gate].level, post_gate);
        // task[post_gate] = 1;
      }
    }

    left_node_sim(); // simulating the value found by backtrace method
    /*
cout << "printing result of left_node_sim1";
for (int i = 0; i < Nnodes; i++)
{
cout << "\n"
<< i << "    " << value1[i] << "   " << value2[i];
}
*/
    // cout << "\nback_gate0=" << back_gate << "   backtracevalue=" << Cin;

    // same thing

    for (int i = 0; i < Node[back_gate].fout; i++) {
      np2 = &Node[back_gate];
      post_gate = np2->dnodes[i]->indx;
      if (task[post_gate] == 0) {
        // cout << "\n insertedEvent2  " << Node[post_gate].level << "  " <<
        // post_gate;
        Store_lev_node(Node[post_gate].level, post_gate);
        // task[post_gate] = 1;
      }
    }

    key = Check_fault_activation(faultindx, faultvalue);

    // cout << "\nkey1=" << key;
    if (faultvalue == 1) {
      value3[faultindx] = 1;
      value4[faultindx] = 1;
    } else {
      value3[faultindx] = 0;
      value4[faultindx] = 0;
    }

    // reason????

    for (int i = 0; i < Node[faultindx].fout; i++) {
      np2 = &Node[faultindx];
      post_gate = np2->dnodes[i]->indx;
      if (task[post_gate] == 0) {
        // cout << "\n insertedEvent3  " << Node[post_gate].level << "  " <<
        // post_gate;
        Store_lev_node(Node[post_gate].level, post_gate);
        // task[post_gate] = 1;
      }
    }

    // simulating with faulty value at gate
    right_node_sim();

    // recursive call to podem for propagating the fault
    if (podem_recursion(faultindx, faultvalue) && key) {
      // cout << "\nenter";
      return true;
    }

    // cout << "\nHello";
    // cout << "\nback_gate2=" << Node[back_gate].num << "   backtracevalue="
    // << Cin;  cout << "\nobjective=" << next_objective << "  " <<
    // object_value;
    Cin = !Cin;
    if (Cin == 0) // Assign values to PI
    {
      value1[back_gate] = 0;
      value2[back_gate] = 0;
      value3[back_gate] = 0;
      value4[back_gate] = 0;
    } else {
      value1[back_gate] = 1;
      value2[back_gate] = 1;
      value3[back_gate] = 1;
      value4[back_gate] = 1;
      // cout << "\nback_gate2=" << back_gate << "   backtracevalue=" << Cin;
    }

    for (int i = 0; i < Node[back_gate].fout; i++) {
      np2 = &Node[back_gate];
      post_gate = np2->dnodes[i]->indx;
      if (task[post_gate] == 0) {
        // cout << "\n insertedEvent4  " << Node[post_gate].level << "  " <<
        // post_gate;
        Store_lev_node(Node[post_gate].level, post_gate);
        // task[post_gate] = 1;
      }
    }

    // cout << "\nback_gate3=" << back_gate << "   backtracevalue=" << Cin;
    left_node_sim(); // simulating the value found by backtrace method

    key = Check_fault_activation(faultindx, faultvalue);
    // cout << "\nkey=" << key;

    for (int i = 0; i < Node[back_gate].fout; i++) {
      np2 = &Node[back_gate];
      post_gate = np2->dnodes[i]->indx;
      if (task[post_gate] == 0) {
        // cout << "\n insertedEvent5  " << Node[post_gate].level << "  " <<
        // post_gate;
        Store_lev_node(Node[post_gate].level, post_gate);
        // task[post_gate] = 1;
      }
    }

    if (faultvalue == 1) {
      value3[faultindx] = 1;
      value4[faultindx] = 1;
      // cout << "\ninif";
    } else {
      value3[faultindx] = 0;
      value4[faultindx] = 0;
      // cout << "inelse";
    }

    for (int i = 0; i < Node[faultindx].fout; i++) {
      np2 = &Node[faultindx];
      post_gate = np2->dnodes[i]->indx;
      if (task[post_gate] == 0) {
        // cout << "\n insertedEvent6  " << Node[post_gate].level << "  " <<
        // post_gate;
        Store_lev_node(Node[post_gate].level, post_gate);
        // task[post_gate] = 1;
      }
    }

    // cout << "\nagain here";

    // simulating with faulty value at gate
    right_node_sim();
    // recursive call to podem for propogating the fault
    if (podem_recursion(faultindx, faultvalue) && key) {
      return true;
    }

    // cout << "\nagain here222222";
    value1[back_gate] = 0;
    value2[back_gate] = 1;

    for (int i = 0; i < Node[back_gate].fout; i++) {
      np2 = &Node[back_gate];
      post_gate = np2->dnodes[i]->indx;
      if (task[post_gate] == 0) {
        // cout << "\n insertedEvent7  " << Node[post_gate].level << "  " <<
        // post_gate;
        Store_lev_node(Node[post_gate].level, post_gate);
        // task[post_gate] = 1;
      }
    }
    left_node_sim(); // simulating the value found by backtrace method

    // cout << "\nsecondtime";
    key = Check_fault_activation(faultindx, faultvalue);
    if (faultvalue == 1) {
      value3[faultindx] = 1;
      value4[faultindx] = 1;
    } else {
      value3[faultindx] = 0;
      value4[faultindx] = 0;
    }

    for (int i = 0; i < Node[faultindx].fout; i++) {
      np2 = &Node[faultindx];
      post_gate = np2->dnodes[i]->indx;
      if (task[post_gate] == 0) {
        // cout << "\n insertedEvent8  " << Node[post_gate].level << "  " <<
        // post_gate;
        Store_lev_node(Node[post_gate].level, post_gate);
        // task[post_gate] = 1;
      }
    }
    // simulating with faulty value at gate
    right_node_sim();
    // cout << "\nendtime";
    // recursive call to podem for propogating the fault

    // cout << "couldn't detect\n";
    return false;
  }

  else {
    // cout << "couldn't detect\n";
    return false;
  }
}

int podem_class::podem(int faultindex, int faultvalue, string outfile) {
  ofstream podem_file;
  podem_file.open(outfile);

  faultindx = faultindex;
  Setup_levl();

  if (podem_recursion(faultindx, faultvalue) == true) {
    // cout<<detected_count<<"\n";
    // myfile << Node[faultindx].indx << " " << faultvalue << " ";
    // detected_count++;

    // char array[4];
    NSTRUC *np2;

    int input_no = 0;
    for (int j = 0; j < Nnodes; j++) // Write the primaty input to output file
    {
      np2 = &Node[j];
      if (np2->type == 0) {
        input_no++;
        //   np2 = &Node[i];
        podem_file << np2->num;
        if (input_no < Npi)
          podem_file << ",";
        // cout << "\nprimary input == " << np->num;
        // cout << "\ninput nodes == "<< np2->num;
      }
    }
    podem_file << "\n";

    // cout << "\nTest_vector=";
    int j;
    int count = 0;

    for (j = 0; j < Nnodes; j++) {

      np2 = &Node[j];
      if (np2->type == 0)

      {
        count++;
        // sprintf(array, "%d%d%d%d", value1[np2->indx], value2[np2->indx],
        // value3[np2->indx], value4[np2->indx]);
        if (value1[np2->indx] == 0 && value2[np2->indx] == 1 &&
            value3[np2->indx] == 0 && value4[np2->indx] == 1) {
          podem_file << "x";
          // cout << "x";
        } else if (value1[np2->indx] == 1 && value2[np2->indx] == 0 &&
                   value3[np2->indx] == 1 && value4[np2->indx] == 0) {
          podem_file << "x";
          // cout << "x";
        } else if (value1[np2->indx] == 1 && value2[np2->indx] == 1 &&
                   value3[np2->indx] == 0 && value4[np2->indx] == 0) {
          podem_file << "1";
          // cout << "1";
        } else if (value1[np2->indx] == 0 && value2[np2->indx] == 0 &&
                   value3[np2->indx] == 1 && value4[np2->indx] == 1) {
          podem_file << "0";
          // cout << "0";
        } else if (value1[np2->indx] == 0 && value2[np2->indx] == 0 &&
                   value3[np2->indx] == 0 && value4[np2->indx] == 0) {
          podem_file << "0";
          // cout << "0";
        } else if (value1[np2->indx] == 1 && value2[np2->indx] == 1 &&
                   value3[np2->indx] == 1 && value4[np2->indx] == 1) {
          podem_file << "1";
          // cout << "1";
        }
        if (count < Npi)
          podem_file << ",";
        // myfile<<"Input: "<<Pinput[j]->num<<" value:
        // "<<value1[Pinput[j]->indx]<<value2[Pinput[j]->indx]<<value3[Pinput[j]->indx]<<value4[Pinput[j]->indx]<<"\n";
      }
    }
    // myfile << "\n";
  }

  return 1;
}

void podem_class::create_vector() {
  podem_test_vector.clear();
  int j;
  NSTRUC *np2;
  for (j = 0; j < Nnodes; j++) {

    np2 = &Node[j];
    if (np2->type == 0) {
      if (value1[np2->indx] == 0 && value2[np2->indx] == 1 &&
          value3[np2->indx] == 0 && value4[np2->indx] == 1) {
        podem_test_vector.push_back(0);
      } else if (value1[np2->indx] == 1 && value2[np2->indx] == 0 &&
                 value3[np2->indx] == 1 && value4[np2->indx] == 0) {
        podem_test_vector.push_back(0);
      } else if (value1[np2->indx] == 1 && value2[np2->indx] == 1 &&
                 value3[np2->indx] == 0 && value4[np2->indx] == 0) {
        podem_test_vector.push_back(1);
      } else if (value1[np2->indx] == 0 && value2[np2->indx] == 0 &&
                 value3[np2->indx] == 1 && value4[np2->indx] == 1) {
        podem_test_vector.push_back(0);
      } else if (value1[np2->indx] == 0 && value2[np2->indx] == 0 &&
                 value3[np2->indx] == 0 && value4[np2->indx] == 0) {
        podem_test_vector.push_back(0);
      } else if (value1[np2->indx] == 1 && value2[np2->indx] == 1 &&
                 value3[np2->indx] == 1 && value4[np2->indx] == 1) {
        podem_test_vector.push_back(1);
      }
    }
  }
}

// GLOBAL variables---only for part4
vector<int> global_reduced_node_num;
vector<int> global_reduced_node_type;

vector<vector<int>> global_associated_node_num;
vector<vector<int>> global_associated_node_type;

void atpg_part4() {

  NSTRUC *np;
  int i, j, m, n, k, eq_in, eq_out, dom_in, dom_out;

  vector<vector<int>> equivalent_node_num;
  vector<vector<int>> equivalent_node_type;

  global_reduced_node_num.clear();
  global_reduced_node_type.clear();

  global_associated_node_num.clear();
  global_associated_node_type.clear();

  // write all the node levels to output file
  for (i = 0; i < Nnodes; i++) {
    np = &Node[i];
    global_reduced_node_num.push_back(np->num);
    global_reduced_node_type.push_back(0);

    global_reduced_node_num.push_back(np->num);
    global_reduced_node_type.push_back(1);
  }

  int total_fault = 2 * Nnodes;

  // levelize
  lev_max = -1;
  vec_lev.clear();
  update_level();

  // equivalence dominance
  int r = 0;

  for (m = 1; m <= lev_max; m++) {
    for (n = 0; n < Nnodes; n++) {
      np = &Node[n];

      if (np->level == m and np->type > 2) {

        equivalent_node_num.push_back(std::vector<int>());
        equivalent_node_type.push_back(std::vector<int>());

        // gate types

        if (np->type == 3) {
          eq_in = 1;
          eq_out = 1;
          dom_in = 0;
          dom_out = 0;
        }
        if (np->type == 4) {
          eq_in = 1;
          eq_out = 0;
          dom_in = 0;
          dom_out = 1;
        }

        if (np->type == 5) {
          eq_in = 0;
          eq_out = 1;
        }

        if (np->type == 6) {
          eq_in = 0;
          eq_out = 1;
          dom_in = 1;
          dom_out = 0;
        }
        if (np->type == 7) {
          eq_in = 0;
          eq_out = 0;
          dom_in = 1;
          dom_out = 1;
        }

        // give priority to gates
        for (k = 0; k < np->fin; k++) {
          if (np->unodes[k]->type != 1) {
            // cout << np->unodes[k]->num;
            equivalent_node_num[r].push_back(np->unodes[k]->num);
            equivalent_node_type[r].push_back(eq_in);
          }
        }

        // collapse the branches

        for (k = 0; k < np->fin; k++) {
          if (np->unodes[k]->type == 1) {
            // cout << np->unodes[k]->num;
            equivalent_node_num[r].push_back(np->unodes[k]->num);
            equivalent_node_type[r].push_back(eq_in);
          }
        }

        // cout << np->num;

        equivalent_node_num[r].push_back(np->num);
        equivalent_node_type[r].push_back(eq_out);
        r = r + 1;

        // extra not gate
        if (np->type == 5) {

          eq_in = 1;
          eq_out = 0;

          equivalent_node_num.push_back(std::vector<int>());
          equivalent_node_type.push_back(std::vector<int>());

          equivalent_node_num[r].push_back(np->unodes[0]->num);
          equivalent_node_type[r].push_back(eq_in);

          equivalent_node_num[r].push_back(np->num);
          equivalent_node_type[r].push_back(eq_out);
          r = r + 1;
        }

        // fault dominance
        if (np->type > 3 and np->type != 5) {

          equivalent_node_num.push_back(std::vector<int>());
          equivalent_node_type.push_back(std::vector<int>());

          equivalent_node_num[r].push_back(np->unodes[0]->num);
          equivalent_node_type[r].push_back(dom_in);

          equivalent_node_num[r].push_back(np->num);
          equivalent_node_type[r].push_back(dom_out);
          r = r + 1;
        }
      }
    }
  }

  // associated list

  for (i = 0; i < global_reduced_node_num.size(); i++) {
    global_associated_node_num.push_back(std::vector<int>());
    global_associated_node_type.push_back(std::vector<int>());
    global_associated_node_num[i].push_back(global_reduced_node_num[i]);
    global_associated_node_type[i].push_back(global_reduced_node_type[i]);

    for (j = 0; j < equivalent_node_num.size(); j++) {
      if (global_reduced_node_num[i] == equivalent_node_num[j][0] &&
          global_reduced_node_type[i] == equivalent_node_type[j][0]) {
        for (k = 1; k < equivalent_node_num[j].size(); k++) {
          global_associated_node_num[i].push_back(equivalent_node_num[j][k]);
          global_associated_node_type[i].push_back(equivalent_node_type[j][k]);
        }
      }
    }
  }

  // print associated list

  int reduced_size = 0;

  // second step
  vector<int> rows_to_remove;
  vector<int> rows_to_add;
  int l;

  for (i = 0; i < global_associated_node_num.size(); i++) {

    for (j = 0; j < global_associated_node_num[i].size(); j++) {

      for (k = i + 1; k < global_associated_node_num.size(); k++) {

        for (l = 0; l < global_associated_node_num[k].size(); l++) {

          if (global_associated_node_num[i][j] ==
                  global_associated_node_num[k][l] &&
              global_associated_node_type[i][j] ==
                  global_associated_node_type[k][l]) {

            // cout << global_associated_node_num[k][l] << " ";
            int ii_value = -1;
            int kk_value = -1;

            for (int gg = 0; gg < rows_to_remove.size(); gg++) {

              if (i == rows_to_remove[gg]) {
                ii_value = rows_to_add[gg];
              }
            }

            for (int gg = 0; gg < rows_to_remove.size(); gg++) {

              if (k == rows_to_remove[gg]) {
                kk_value = rows_to_add[gg];
              }
            }

            if (ii_value != -1 and kk_value == -1) {
              rows_to_remove.push_back(k);
              rows_to_add.push_back(ii_value);
            }

            if (ii_value == -1 and kk_value != -1) {
              rows_to_remove.push_back(i);
              rows_to_add.push_back(kk_value);
            }

            if (ii_value == -1 and kk_value == -1) {
              rows_to_remove.push_back(k);
              rows_to_add.push_back(i);
            }
          }
        }
      }
    }
  }

  vector<int> mod_rows_to_remove;
  vector<int> mod_rows_to_add;

  for (int i = 0; i < rows_to_remove.size(); i++) {
    int match = 0;
    for (j = 0; j < mod_rows_to_remove.size(); j++) {
      if (rows_to_remove[i] == mod_rows_to_remove[j]) {
        match = 1;
        break;
      }
    }
    if (match == 0) {
      mod_rows_to_add.push_back(rows_to_add[i]);
      mod_rows_to_remove.push_back(rows_to_remove[i]);
    }
  }

  for (int p = 0; p < mod_rows_to_add.size(); p++) {
    int index1 = mod_rows_to_add[p];
    int index2 = mod_rows_to_remove[p];
    // global_associated_node_num[index1].push_back(global_reduced_node_num[index2]);
    // global_associated_node_type[index1].push_back(global_reduced_node_type[index2]);

    int match = 0;
    for (j = 0; j < global_associated_node_num[index1].size(); j++) {
      // cout<<"OKhere???";
      if (global_associated_node_num[index1][j] ==
              global_reduced_node_num[index2] &&
          global_associated_node_type[index1][j] ==
              global_reduced_node_type[index2]) {
        match = 1;
        break;
      }
    }
    if (match == 0) {

      global_associated_node_num[index1].push_back(
          global_reduced_node_num[index2]);
      global_associated_node_type[index1].push_back(
          global_reduced_node_type[index2]);
    }

    // insert others

    for (i = 0; i < global_associated_node_num[index2].size(); i++) {
      int match = 0;
      for (j = 0; j < global_associated_node_num[index1].size(); j++) {
        // cout<<"OKhere???";
        if (global_associated_node_num[index1][j] ==
                global_associated_node_num[index2][i] &&
            global_associated_node_type[index1][j] ==
                global_associated_node_type[index2][i]) {
          match = 1;
          break;
        }
      }
      if (match == 0) {
        // cout << "\nnon  " << global_associated_node_num[index2][i] << "  "
        // << global_associated_node_type[index2][i] << "  " << index1;
        global_associated_node_num[index1].push_back(
            global_associated_node_num[index2][i]);
        global_associated_node_type[index1].push_back(
            global_associated_node_type[index2][i]);
      }
    }
  }

  for (i = 0; i < mod_rows_to_remove.size(); i++) {
    global_reduced_node_num.erase(global_reduced_node_num.begin() +
                                  mod_rows_to_remove[i]);
    global_reduced_node_type.erase(global_reduced_node_type.begin() +
                                   mod_rows_to_remove[i]);
    global_associated_node_num.erase(global_associated_node_num.begin() +
                                     mod_rows_to_remove[i]);
    global_associated_node_type.erase(global_associated_node_type.begin() +
                                      mod_rows_to_remove[i]);
    if (i < mod_rows_to_remove.size() - 1) {
      for (j = i + 1; j < mod_rows_to_remove.size(); j++) {
        if (mod_rows_to_remove[j] > mod_rows_to_remove[i])
          mod_rows_to_remove[j]--;
      }
    }
  }

  // Third Step

  rows_to_remove.clear();
  rows_to_add.clear();

  int count = 0;
  for (i = 0; i < global_associated_node_num.size(); i++) {

    for (j = 1; j < global_associated_node_num[i].size(); j++) {

      for (k = i + 1; k < global_associated_node_num.size(); k++) {

        for (l = 1; l < global_associated_node_num[k].size(); l++) {

          if (global_associated_node_num[i][j] ==
                  global_associated_node_num[k][l] &&
              global_associated_node_type[i][j] ==
                  global_associated_node_type[k][l]) {

            count++;
            rows_to_remove.push_back(i);
            rows_to_add.push_back(j);
            break;
          }
        }
      }
    }
  }

  // cout << "\nOK=\n";
  for (i = 0; i < rows_to_remove.size(); i++) {

    global_associated_node_num[rows_to_remove[i]].erase(
        global_associated_node_num[rows_to_remove[i]].begin() + rows_to_add[i]);
    global_associated_node_type[rows_to_remove[i]].erase(
        global_associated_node_type[rows_to_remove[i]].begin() +
        rows_to_add[i]);
  }

  // cout << "\nOK=\n";
  for (i = 0; i < global_associated_node_num.size(); i++) {

    global_associated_node_num[i].erase(global_associated_node_num[i].begin() +
                                        0);
    global_associated_node_type[i].erase(
        global_associated_node_type[i].begin() + 0);
  }
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~END OF
// PODEM~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// PART3..........................................................................................................................................
void atpg_det(char *cp) {
  // Do the read here
  // cout<<"here";
  cread(cp);

  // cout<<"here2";

  char bufInit[MAXLINE];
  char bufInit2[MAXLINE];

  char *spaceIndx;
  spaceIndx = strchr(cp + 1, ' ');
  *spaceIndx = '\0';
  sscanf(cp + 1, "%s", bufInit);
  // sscanf(bufInit, "%s", cirName);

  char *cp2 = spaceIndx + 1;
  sscanf(cp2, "%s", bufInit2);
  // sscanf(bufInit, "%s", algName);

  int dalg_or_podem = -1;

  string selection = bufInit2;

  if (selection == "DALG") {
    dalg_or_podem = 0;
  } else if (selection == "PODEM") {
    dalg_or_podem = 1;
  } else {
    dalg_or_podem = -1;
  }

  NSTRUC *np;
  int i, j, m, n, k, eq_in, eq_out, dom_in, dom_out;

  vector<int> reduced_node_num;
  vector<int> reduced_node_type;

  // checkpoint theorem
  for (i = 0; i < Nnodes; i++) {
    np = &Node[i];
    if (np->type == 0 or np->type == 1) {
      reduced_node_num.push_back(np->num);
      reduced_node_type.push_back(0);

      reduced_node_num.push_back(np->num);
      reduced_node_type.push_back(1);
    }
  }

  /*
    cout << "\nReduced list\n";

    for (int i = 0; i < reduced_node_num.size(); i++)
    {
      cout << reduced_node_num[i] << " ";
      co
      
  */

  // ------------------------------------------------------ EDIT HERE
  // -----------------------------------------------------------------------
  // char *algorithm_name = "DALG";
  // auto timeDuration;
  // float finalDuration;

  string bufStr1 = ckt_name + "_" + selection + "_ATPG_report.txt";
  string bufStr2 = ckt_name + "_" + selection + "_ATPG_patterns.txt";

  ofstream myfile1;
  ofstream myfile2;

  myfile1.open(bufStr2);
  myfile2.open(bufStr1);

  myfile2 << "Algorithm: " << selection << "\n";
  myfile2 << "Circuit: " << ckt_name << "\n";

  int input_no = 0;

  update_level();

  // Write the primaty input to output file
  for (int j = 0; j < Nnodes; j++) {
    np = &Node[j];
    if (np->type == 0) {
      input_no++;
      //   np2 = &Node[i];
      myfile1 << np->num;
      if (input_no < Npi)
        myfile1 << ",";
    }
  }

  int detected_fault = 0;
  float fault_coverage = 0;

  // total detected fault
  vector<int> total_faulty_nodes;
  vector<int> total_fault_types;

  vec_input_id.clear();

  for (int k = 0; k < Npi; k++) {
    np = Pinput[k];
    vec_input_id.push_back(np->num);
  }

  // if algorithm is D
  if (dalg_or_podem == 0) {
    auto start = chrono::steady_clock::now();
    for (int i = 0; i < reduced_node_num.size(); i++) {
      int match = 0;

      for (int ii = 0; ii < total_faulty_nodes.size(); ii++) {
        if (total_faulty_nodes[ii] == reduced_node_num[i] and
            total_fault_types[ii] == reduced_node_type[i]) {
          match = 1;
          break;
        }
      }

      if (match == 1)
        continue;

      test_vector.clear();
      global_reset_d();
      Dalg_pattern.clear();
      if (dalg_l(reduced_node_num[i], reduced_node_type[i])) {

        // write pattern file
        myfile1 << "\n";
        for (int jj = 0; jj < test_vector.size(); jj++) {
          myfile1 << test_vector[jj];
          if (jj < test_vector.size() - 1)
            myfile1 << ",";
        }

        // do the dfs for this pattern
        vec_logic.clear();
        vec_faultlist_id.clear();
        vec_faultlist_value.clear();
        vec_inputpattern.clear();

        vec_logic.push_back(test_vector);

        vec_inputpattern = test_vector;

        update_logic(0, 1); // doing logic simulation

        update_dfs(1);

        // collect all in total_fault_list

        for (int m = 0; m < vec_faultlist_id.size(); m++) {
          int match = 0;
          for (int n = 0; n < total_faulty_nodes.size(); n++) {
            if ((total_faulty_nodes[n] == vec_faultlist_id[m]) &&
                (total_fault_types[n] == vec_faultlist_value[m])) {
              match++;
            }
          }
          if (!match) {
            total_faulty_nodes.push_back(vec_faultlist_id[m]);
            total_fault_types.push_back(vec_faultlist_value[m]);
          }
        }
      }
    }

    // cout << "\nfault_coverage= ";
    fault_coverage =
        ((float)total_faulty_nodes.size()) / ((float)Nnodes) / ((float)2);
    fault_coverage = fault_coverage * 100;

    myfile2 << "Fault Coverage: " << setprecision(2) << fixed << fault_coverage
            << "%\n";

    auto end = chrono::steady_clock::now();

    auto required_time = end - start;

    myfile2 << "Time: " << setprecision(10)
            << chrono::duration<double, nano>(required_time).count() / 1e9
            << " seconds"
            << "\n";
  }

  // if algorithm is podem
  else if (dalg_or_podem == 1) {
    auto start = chrono::steady_clock::now();
    for (int i = 0; i < reduced_node_num.size(); i++) {
      int match = 0;

      for (int ii = 0; ii < total_faulty_nodes.size(); ii++) {
        if (total_faulty_nodes[ii] == reduced_node_num[i] and
            total_fault_types[ii] == reduced_node_type[i]) {
          match = 1;
          break;
        }
      }

      if (match == 1)
        continue;

      podem_test_vector.clear();

      if (podem_atpg(reduced_node_num[i], reduced_node_type[i])) {

        // write pattern file
        myfile1 << "\n";
        for (int jj = 0; jj < podem_test_vector.size(); jj++) {
          myfile1 << podem_test_vector[jj];
          if (jj < podem_test_vector.size() - 1)
            myfile1 << ",";
        }

        // do the dfs for this pattern
        vec_logic.clear();
        vec_faultlist_id.clear();
        vec_faultlist_value.clear();
        vec_inputpattern.clear();

        vec_logic.push_back(podem_test_vector);

        vec_inputpattern = podem_test_vector;

        update_logic(0, 1); // doing logic simulation

        update_dfs(1);

        // collect all in total_fault_list

        for (int m = 0; m < vec_faultlist_id.size(); m++) {
          int match = 0;
          for (int n = 0; n < total_faulty_nodes.size(); n++) {
            if ((total_faulty_nodes[n] == vec_faultlist_id[m]) &&
                (total_fault_types[n] == vec_faultlist_value[m])) {
              match++;
            }
          }
          if (!match) {
            total_faulty_nodes.push_back(vec_faultlist_id[m]);
            total_fault_types.push_back(vec_faultlist_value[m]);
          }
        }
      }
    }

    // cout << "\nfault_coverage= ";
    fault_coverage =
        ((float)total_faulty_nodes.size()) / ((float)Nnodes) / ((float)2);
    fault_coverage = fault_coverage * 100;

    myfile2 << "Fault Coverage: " << setprecision(2) << fixed << fault_coverage
            << "%\n";

    auto end = chrono::steady_clock::now();

    auto required_time = end - start;

    myfile2 << "Time: " << setprecision(10)
            << chrono::duration<double, nano>(required_time).count() / 1e9
            << " seconds"
            << "\n";
  }

  else {
    cout << "Chose Right Algorithm";
  }

  // cout << setprecision(2) << fixed << fault_coverage << "\n";

  // myfile2 << "Time: " << finalDuration << " seconds";
}
/*-----------------------------------------------------------------------
input: nothing
output: nothing
called by: ATPG_pre
description:
  final product.
-----------------------------------------------------------------------*/

/*-----------------------------------------------------------------------
input: nothing
output: nothing
called by: ATPG
description:
  final product.
-----------------------------------------------------------------------*/
vector<int> get_random_pattern(unsigned long int num, int digit) {
  vector<int> itob;
  itob.assign((digit), 2);
  for (int i = 0; i < digit; i++) {
    int k = num >> i;
    if (k & 1)
      itob[i] = 1;
    else
      itob[i] = 0;
  }
  return itob;
}

void atpg(char *cp) {
  cread(cp);
  update_level();
  vector<int> total_fault_id;
  vector<int> total_fault_value;
  for (int i = 0; i < Nnodes; i++) {
    NSTRUC *p;
    p = &Node[i];
    total_fault_id.push_back(p->num);
    total_fault_id.push_back(p->num);
    total_fault_value.push_back(0);
    total_fault_value.push_back(1);
  }
  string buf, buf1;
  string str1 = "_ATPG_patterns.txt";
  string str2 = "_ATPG_report.txt";
  buf = ckt_name;
  buf1 = ckt_name;
  buf.append(str1);
  buf1.append(str2);
  ofstream fd1;
  fd1.open(buf);
  ofstream fd2;
  fd2.open(buf1);

  int flag = 0;
  vec_input_id.clear();
  vec_logic.clear();
  vec_faultlist_id.clear();
  vec_faultlist_value.clear();
  test_vector.clear();
  float total_fault = (2.00) * Nnodes;
  vector<int> atpg_fault_id;
  vector<int> atpg_fault_value;
  vector<int> one_pattern;
  float atpg_fault_coverage = 0;
  auto start = chrono::steady_clock::now();
  for (int i = 0; i < Npi; i++) {
    vec_input_id.push_back(Pinput[i]->num);
    fd1 << Pinput[i]->num;
    if (i < (Npi - 1)) {
      fd1 << ',';
    }
  }
  fd1 << endl;
  fd2 << "Algorithm: Random pattern fault simulation, DALG" << endl;
  fd2 << "Circuit: " << ckt_name << endl;
  // fd2 << "Firstly test all 0 input patterns and all 1 input patterns "
  //        "(special "
  //        "case): \n";
  one_pattern.assign(Npi, 0);
  vec_logic.push_back(one_pattern);
  one_pattern.assign(Npi, 1);
  vec_logic.push_back(one_pattern);
  for (unsigned int i = 0; i < vec_logic.size(); i++) {
    for (unsigned int j = 0; j < vec_logic[i].size(); j++) {
      fd1 << vec_logic[i][j];
      if (j < (vec_logic[i].size() - 1)) {
        fd1 << ',';
      }
    }
    fd1 << endl;
  }
  update_logic(flag, 2);
  update_dfs(2);

  for (int m = 0; m < vec_faultlist_id.size(); m++) {
    int match = 0;
    for (int n = 0; n < atpg_fault_id.size(); n++) {
      if ((atpg_fault_id[n] == vec_faultlist_id[m]) &&
          (atpg_fault_value[n] == vec_faultlist_value[m])) {
        ++match;
        break;
      }
    }
    if (!match) {
      atpg_fault_id.push_back(vec_faultlist_id[m]);
      atpg_fault_value.push_back(vec_faultlist_value[m]);
    }
  }

  atpg_fault_coverage = 100 * (((float)atpg_fault_id.size()) / total_fault);
  // fd2 << "fault coverage: " << atpg_fault_coverage << endl;

  // fd2 << "Now do random test patterns: \n";
  int judge_num = 3;
  vector<float> difference;
  difference.assign(judge_num, 100.00);
  int frequency = Nnodes / 20 + 1;

  while (atpg_fault_coverage < 100) {
    for (int i = 0; i < judge_num; i++) {
      float temp_coverage;
      vec_logic.clear();
      vec_faultlist_id.clear();
      vec_faultlist_value.clear();
      for (int j = 0; j < frequency; j++) {
        // int range = (int)pow(2, Npi);
        vector<int> random_pattern;
        for (int e = 0; e < Npi; e++) {
          int random_number = rand() % 2;
          random_pattern.push_back(random_number);
        }
        vec_logic.push_back(random_pattern);
        random_pattern.clear();
      }
      for (unsigned int i = 0; i < vec_logic.size(); i++) {
        for (unsigned int j = 0; j < vec_logic[i].size(); j++) {
          fd1 << vec_logic[i][j];
          if (j < (vec_logic[i].size() - 1)) {
            fd1 << ',';
          }
        }
        fd1 << endl;
      }
      // print_2d(vec_logic);
      update_logic(flag, frequency);
      update_dfs(frequency);
      for (int m = 0; m < vec_faultlist_id.size(); m++) {
        int match = 0;
        for (int n = 0; n < atpg_fault_id.size(); n++) {
          if ((atpg_fault_id[n] == vec_faultlist_id[m]) &&
              (atpg_fault_value[n] == vec_faultlist_value[m])) {
            match++;
            break;
          }
        }
        if (!match) {
          atpg_fault_id.push_back(vec_faultlist_id[m]);
          // print_1d(atpg_fault_id);
          atpg_fault_value.push_back(vec_faultlist_value[m]);
          // print_1d(atpg_fault_value);
        }
      }
      temp_coverage = 100 * (((float)atpg_fault_id.size()) / total_fault);
      difference[i] = temp_coverage - atpg_fault_coverage;
      atpg_fault_coverage = temp_coverage;
      // cout << "fault coverage: " << atpg_fault_coverage << endl;
    }

    int count = 0;
    for (int r = 0; r < judge_num; r++) {
      if (difference[r] < 2.00) {
        ++count;
      }
    }
    // if ((count == judge_num) && (duration.count() > 0.00000000001)) {
    //   break;
    // }
    if (count == judge_num) {
      break;
    }
  }
  // cout << "fault coverage does not reach 100%, do ATPG: \n";
  if (atpg_fault_coverage != 100) {

    for (int j = 0; j < total_fault_id.size(); j++) {
      for (int q = 0; q < atpg_fault_id.size(); q++) {
        if ((total_fault_id[j] == atpg_fault_id[q]) &&
            (total_fault_value[j] == atpg_fault_value[q])) {
          total_fault_id[j] = -1;
          total_fault_value[j] = -1;
        }
      }
    }
    total_fault_id.erase(
        remove(total_fault_id.begin(), total_fault_id.end(), -1),
        total_fault_id.end());
    total_fault_value.erase(
        remove(total_fault_value.begin(), total_fault_value.end(), -1),
        total_fault_value.end());
    // print_1d(total_fault_id);
    // print_1d(total_fault_value);
    int count = 1;
    while (count) {
      count = 0;
      int node_num, stuck_fault;
      int index;
      for (int i = 0; i < total_fault_id.size(); i++) {
        if ((total_fault_id[i] != (-2)) && (total_fault_value[i] != (-2))) {
          node_num = total_fault_id[i];
          stuck_fault = total_fault_value[i];
          index = i;
          break;
        }
      }
      if (dalg_l(node_num, stuck_fault) == true) {
        for (int r = 0; r < Npi; r++) {
          string temp;
          if (test_vector[r] == X) {
            temp = '0';
          }
          if ((test_vector[r] == D) || (test_vector[r] == 1)) {
            temp = '1';
          }
          if ((test_vector[r] == D_bar) || (test_vector[r] == 0)) {
            temp = '0';
          }
          fd1 << temp;
          if (r < Npi - 1) {
            fd1 << ',';
          }
        }
        fd1 << endl;
        vec_logic.clear();
        vec_faultlist_id.clear();
        vec_faultlist_value.clear();
        vec_logic.push_back(test_vector);
        update_logic(flag, 1);
        update_dfs(1);
        int search = 0;
        for (int r = 0; r < vec_faultlist_id.size(); r++) {
          if ((vec_faultlist_id[r] == node_num) &&
              (vec_faultlist_value[r] == stuck_fault)) {
            ++search;
            break;
          }
        }
        if (!search) {
          total_fault_id[index] = -2;
          total_fault_value[index] = -2;
        }
        for (int j = 0; j < total_fault_id.size(); j++) {
          for (int q = 0; q < vec_faultlist_id.size(); q++) {
            if ((total_fault_id[j] == vec_faultlist_id[q]) &&
                (total_fault_value[j] == vec_faultlist_value[q])) {
              total_fault_id[j] = -1;
              total_fault_value[j] = -1;
            }
          }
        }
        total_fault_id.erase(
            remove(total_fault_id.begin(), total_fault_id.end(), -1),
            total_fault_id.end());
        total_fault_value.erase(
            remove(total_fault_value.begin(), total_fault_value.end(), -1),
            total_fault_value.end());
      } else {
        for (int i = 0; i < total_fault_id.size(); i++) {
          if ((total_fault_id[i] == node_num) &&
              (total_fault_value[i] == stuck_fault)) {
            total_fault_id[i] = -2;
            total_fault_value[i] = -2;
            break;
          }
        }
      }
      for (int i = 0; i < total_fault_id.size(); i++) {
        if ((total_fault_id[i] != (-2)) && (total_fault_value[i] != (-2))) {
          ++count;
          break;
        }
      }
    }
    atpg_fault_coverage =
        100 * ((float)1.0 - (((float)total_fault_id.size()) / total_fault));
  }
  fd2 << "Fault Coverage: " << atpg_fault_coverage << "%" << endl;
  auto end = chrono::steady_clock::now();
  auto required_time = end - start;
  fd2 << "Time: " << setprecision(10)
      << chrono::duration<double, nano>(required_time).count() / 1e9
      << " seconds"
      << "\n";
  fd1.close();
  fd2.close();
}
/*-----------------------------------------------------------------------
input: nothing
output: nothing
called by: main
description:
  The routine prints ot help inormation for each command.
-----------------------------------------------------------------------*/
void help(char *cp) {
  printf("READ filename - ");
  printf("read in circuit file and creat all data structures\n");
  printf("PC - ");
  printf("print circuit information\n");
  printf("HELP - ");
  printf("print this help information\n");
  printf("QUIT - ");
  printf("stop and exit\n");
  printf("LEV - ");
  printf("print levelization information\n");
}

/*-----------------------------------------------------------------------
input: nothing
output: nothing
called by: main
description:
  Set Done to 1 which will terminates the program.
-----------------------------------------------------------------------*/
void quit(char *cp) { Done = 1; }

/*======================================================================*/

/*-----------------------------------------------------------------------
input: nothing
output: nothing
called by: cread
description:
  This routine clears the memory space occupied by the previous circuit
  before reading in new one. It frees up the dynamic arrays Node.unodes,
  Node.dnodes, Node.flist, Node, Pinput, Poutput, and Tap.
-----------------------------------------------------------------------*/
void clear() {
  int i;
  for (i = 0; i < Nnodes; i++) {
    delete[](Node[i].unodes);
    delete[](Node[i].dnodes);
  }

  delete[](Node);
  delete[](Pinput);
  delete[](Poutput);
  // delete[](PODEM_inst);
  delete[](FB_array);
  Nfb = 0;
  Nnodes = 0; /* number of nodes */
  Npi = 0;    /* number of primary inputs */
  Npo = 0;
  lev_max = 0;

  vec_faultlist_wid.clear();
  vec_faultlist_wvalue.clear();
  vec_faultlist_pid.clear();
  vec_faultlist_pvalue.clear();
  vec_detectlist.clear();

  // pfs;
  global_reduced_node_num.clear();
  global_reduced_node_type.clear();

  global_associated_node_num.clear();
  global_associated_node_type.clear();

  Dalg_pattern.clear();
  j_frontier.clear();
  d_frontier.clear();
  event_node_list.clear();
  test_vector.clear();
  vec_faultlist_id.clear();
  vec_faultlist_value.clear();

  vec_inputpattern.clear();
  vec_input_id.clear();
  vec_logic.clear();
  vec_lev.clear();
  podem_node_index_queue.clear();

  Gstate = EXEC;
}

/*-----------------------------------------------------------------------
input: nothing
output: nothing
called by: cread
description:
  This routine allocatess the memory space required by the circuit
  description data structure. It allocates the dynamic arrays Node,
  Node.flist, Node, Pinput, Poutput, and Tap. It also set the default
  tap selection and the fanin and fanout to 0.
-----------------------------------------------------------------------*/
void allocate() {
  int i;
  Node = new NSTRUC[Nnodes];
  Pinput = new NSTRUC *[Npi];
  Poutput = new NSTRUC *[Npo];
  FB_array = new NSTRUC *[Nfb];
  // Node = (NSTRUC *)malloc(Nnodes * sizeof(NSTRUC));
  // Pinput = (NSTRUC **)malloc(Npi * sizeof(NSTRUC *));
  // Poutput = (NSTRUC **)malloc(Npo * sizeof(NSTRUC *));
  // FB_array = (NSTRUC **)malloc(Nfb * sizeof(NSTRUC *));
  for (i = 0; i < Nnodes; i++) {
    Node[i].indx = i;
    Node[i].fin = Node[i].fout = 0;
  }
}

/*-----------------------------------------------------------------------
input: gate type
output: string of the gate type
called by: pc
description:
  The routine receive an integer gate type and return the gate type in
  character string.
-----------------------------------------------------------------------*/
string gname(int tp) {
  switch (tp) {
  case 0:
    return ("PI");
  case 1:
    return ("BRANCH");
  case 2:
    return ("XOR");
  case 3:
    return ("OR");
  case 4:
    return ("NOR");
  case 5:
    return ("NOT");
  case 6:
    return ("NAND");
  case 7:
    return ("AND");
  default:
    return ("ERROR");
  }
}
/*========================= End of program ============================*/