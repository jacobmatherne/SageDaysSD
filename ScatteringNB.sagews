︠5eb3254e-f571-4a56-b517-004312f2cb67s︠
class SDTable():
    """
        SDTable() initializes an object containing a dictionary of model scattering diagrams, for the purpose of looking up multiplicities in collisions
    """
    def __init__(self):
        self.diagrams= {};

    def __repr__(self):
        return "A table of model scattering diagrams"

    def multiplicity(self,d,n,verbose=False):
        """
            multiplicity() looks up the desired multiplicity, and creates or improves the table as necessary

            d: a tuple which determines which diagram is being considered
            n: the normal of the wall whose multiplicity is being considered
        """
        #first, the inputs are switched if decreasing
        if d[0]>d[1]:
            d=(d[1],d[0]);
            n=(n[1],n[0]);
        #checks if the desired diagram exists, and if not, creates it
        if not(d in self.diagrams):
            self.diagrams[d]=ScatteringDiagram([SDWall((0,1),point=(0,-random())),SDWall((0,1),d=d[1]-1),SDWall((1,0),d=d[0])]);
            if verbose:
                print "Model "+str(d)+" created";
        #checks if the desired diagram has high enough order to produce the desired multiplicity
        while self.diagrams[d].order<n[0]+n[1]:
            if verbose:
                print "Attempting to improve model "+str(d)+" to order "+str(self.diagrams[d].order+1);
            self.diagrams[d].improve(verbose=verbose);
            if verbose:
                print "Model "+str(d)+" improved to order "+str(self.diagrams[d].order);
        #returns the desired multiplicity
        if n in self.diagrams[d].multiplicities:
            return self.diagrams[d].multiplicities[n];
        else:
            return 0;

    def mtable(self,d,ord,verbose=False):
        """
            mtable() prints a table of the multiplicities of the walls in the model scattering diagram d, up to order ord.

            d: a tuple which determines which diagram is being considered
            ord: the minimum desired order of the diagram.  If the current order is larger than ord, then the larger order is used.
        """
        self.multiplicity(d,(1,ord-1),verbose=verbose);
        for i in range(ord+1):
            print [self.multiplicity(d,(ord-i,j)) for j in range(0,i+1)];

    def GHKKTerm(self,d,n,denom=1):
        """
            GHKKTerm() computes the scattering term (in the sense of GHKK) in the model scattering diagram d, on the ray with normal n.

            d: a tuple which determines which diagram is being considered
            n: the normal of the wall whose GHKK term is being considered
        """
        R.<x>=PowerSeriesRing(ZZ)
        prec=floor((self.diagrams[d].order)/(n[0]+n[1]))+1
        L=[(1+x^i+O(x^prec))^(self.multiplicity(d,(i*n[0],i*n[1]))/denom) for i in range(prec)];
        return reduce(lambda a,b:a*b,L,1)

DefaultTable=SDTable();

class SDWall:
    """
        SDWall creates an object which encodes a wall inside a 2-dimensional scattering diagram with B=J.

        n: A tuple of integers normal to the wall
        source: None if the wall is a line, or a tuple describing the point of origin of the wall if it is a ray
        multi: An integer counting how many copies of the wall are being described

        Examples:
        sage: SDWall((0,1))
        A line through the point (0, 0) with normal vector (0, 1)
        sage: SDWall((1,1),point=(0,-1),d=3)
        A line through the point (3, 0.600000000000000) with normal vector (1, 1) and multiplicity 3
    """
    def __init__(self,n,point=(0,0),d=1,source=None):
        self.source=source;
        self.is_ray=(source!=None);
        if self.is_ray:
            self.point=source.point;
        else:
            self.point=point;
        self.n=n;
        self.d=d;
        #gcd stores the gcd of the coordinates of the normal covector n
        self.gcd=gcd(n[0],n[1]);
        #order stores the sum of the coordinates of the normal covector n
        self.order=n[0]+n[1];
        #offset is the value of the normal covector on the source point; it is used by collision computations
        self.offset=n[0]*point[0]+n[1]*point[1]+(10^(-12))*random();
        #if the gcd>1, the support of the wall is perturbed by a small amount.  The magnitude of this perturbation can be controlled with the value of self.perturb.
        self.perturb=10^(-6);
        if self.gcd==1:
            self.nreal=self.n;
        else:
            self.theta=uniform(0,self.perturb);
            self.nreal=(float(cos(self.theta)*n[0]-sin(self.theta)*n[1]),float(sin(self.theta)*n[0]+cos(self.theta)*n[1]));

    def __repr__(self):
        if self.is_ray:
            output = "An outgoing ray starting at "+str(self.point)+" with normal vector "+ str(self.n)
        else:
            output = "A line through the point "+str(self.point)+" with normal vector "+ str(self.n)
        if self.d!=1:
            output += " and multiplicity "+str(self.d);
        return output

    def draw(self,xmin,xmax,ymin,ymax):
        """
            draw() returns a graphics object depicting the wall in the specified range
        """
        wallcolor=(1-1/float(self.d),0,1/float(self.d));
        if self.is_ray:
            if xmin>self.point[0] or xmax<self.point[0] or ymin>self.point[1] or ymax<self.point[1]:
                return None;
            else:
                if self.n[0]==0:
                    t= (xmax-self.point[0])/self.n[1];
                elif self.n[1]==0:
                    t=(-ymin+self.point[1])/self.n[0];
                else:
                    t=min((xmax-self.point[0])/self.n[1],(-ymin+self.point[1])/self.n[0]);
                return line([self.point,(self.point[0]+t*self.n[1],self.point[1]-t*self.n[0])],rgbcolor=wallcolor);
        else:
            if self.n[0]==0:
                t1= (xmin-self.point[0])/self.n[1];
                t2= (xmax-self.point[0])/self.n[1];
            elif self.n[1]==0:
                t1=(-ymin+self.point[1])/self.n[0];
                t2=(-ymax+self.point[1])/self.n[0];
            else:
                t1=min((xmin-self.point[0])/self.n[1],(-ymax+self.point[1])/self.n[0]);
                t2=min((xmax-self.point[0])/self.n[1],(-ymin+self.point[1])/self.n[0]);
            return line([(self.point[0]+t1*self.n[1],self.point[1]-t1*self.n[0]),(self.point[0]+t2*self.n[1],self.point[1]-t2*self.n[0])],rgbcolor=wallcolor);

    def collide(self,wall,table=DefaultTable):
        """
            collide() inputs an SDWall, outputs a new SDVertex at the common intersection, or None there is no such intersection (or the walls are parallel)
        """
        det=self.n[0]*wall.n[1]-self.n[1]*wall.n [0];
        detreal=self.nreal[0]*wall.nreal[1]-self.nreal[1]*wall.nreal[0];
        #to prevent numerical error from creating incorrect collisions, we require that the walls intersect by a minimum amount eps.
        eps=10^(-12);
        if det>0:
            #Case: self wall is clockwise from input wall
            if ((self.point[0]-wall.point[0])*self.nreal[0]+(self.point[1]-wall.point[1])*self.nreal[1]>eps or not(wall.is_ray)) and ((self.point[0]-wall.point[0])*wall.nreal[0]+(self.point[1]-wall.point[1])*wall.nreal[1]>eps or not(self.is_ray)):
                intersection=( (wall.nreal[1]*self.offset-self.nreal[1]*wall.offset)/detreal,(-wall.nreal[0]*self.offset+self.nreal[0]*wall.offset)/detreal);
                return SDVertex(intersection,self,wall,table=table);
            else:
                return None;
        elif det<0:
            #Case: self wall is counterclockwise from input wall
            if ((self.point[0]-wall.point[0])*self.nreal[0]+(self.point[1]-wall.point[1])*self.nreal[1]<-eps or not(wall.is_ray)) and ((self.point[0]-wall.point[0])*wall.nreal[0]+(self.point[1]-wall.point[1])*wall.nreal[1]<-eps or not(self.is_ray)):
                intersection=( (wall.nreal[1]*self.offset-self.nreal[1]*wall.offset)/detreal,(-wall.nreal[0]*self.offset+self.nreal[0]*wall.offset)/detreal);
                return SDVertex(intersection,wall,self,table=table);
            else:
                return None;
        else:
            return None;

class SDVertex:
    """
        SDVertex(point,w1,w2) creates an object which encodes the collision vertex betweent two SDWalls.  Intended to be created by SDWall.collide(); not intended for external creation.

        point: a tuple denoting the location of the collision.
        w1,w2: Two SDWalls encoding the walls which define the collision.
    """
    def __init__(self,point,w1,w2,table=DefaultTable):
        self.point=point;
        #switches order of defining rays, to ensure cross product is positive
        self.det=w1.n[0]*w2.n[1]-w1.n[1]*w2.n[0];
        if self.det<0:
            (w1,w2)=(w2,w1);
            self.det=-self.det;
        self.w1=w1;
        self.w2=w2;
        self.table=table;
        #self.exponents is the 2-tuple which describes the exponents in the inflation of the vertex
        self.exponents=(self.det*self.w1.d/self.w1.gcd,self.det*self.w2.d/self.w2.gcd);
        #self.ordergcd is is the gcd of the orders of n1 and n2
        self.ordergcd=gcd(self.w1.order,self.w2.order);
        #nexta is a list of elements of the form (a1,a2,lambda), such that a1*w1.n+a2*w2.n is the first wall of order lambda produced, and all the other walls with the same lambda are of the form (a1,a2)+i*aincrement.
        self.nexta =[(i,1,i*self.w1.order+self.w2.order) for i in range(1,(self.w2.order)/self.ordergcd+1)];
        self.nextorder = self.nexta[0][0]*self.w1.order+self.nexta[0][1]*self.w2.order;
        self.aincrement=(self.w2.order/self.ordergcd,-self.w1.order/self.ordergcd);

    def __repr__(self):
        return "A vertex at point "+str(self.point);

    def improve(self,verbose=False):
        """
            improve() increases the order of the vertex, and returns a list of walls required to increase the order
        """
        if self.nextorder!=100000:
            newwalls=[];
            if self.nextorder==(self.w1.order+self.w2.order):
            #The first time a vertex is improved, only a single wall is added in a predictable way.  This doesn't use the DT table, which eliminates the need for unnecessary recursions.
                newn=(self.w1.n[0]+self.w2.n[0],self.w1.n[1]+self.w2.n[1])
                newwalls = [SDWall(newn,point=self.point,d=(self.w1.d*self.w2.d*self.det)*gcd(newn[0],newn[1])/(self.w1.gcd*self.w2.gcd),source=self)];
            else:
            #Otherwise, the vertex looks up which walls need to be added on the DT table.
                for i in range(ceil(self.nexta[0][1]/float(-self.aincrement[1]))):
                #computes relative and absolute exponent of the new wall
                    currenta=(self.nexta[0][0]+i*self.aincrement[0],self.nexta[0][1]+i*self.aincrement[1]);
                    currentn=(currenta[0]*self.w1.n[0]+currenta[1]*self.w2.n[0],currenta[0]*self.w1.n[1]+currenta[1]*self.w2.n[1]);
                    #looks up the multiplicity of the newly spawned wall
                    multi=(self.table.multiplicity(self.exponents,currenta,verbose=verbose)*gcd(currentn[0],currentn[1]))/(self.det*gcd(currenta[0],currenta[1]));
                    #spawns a wall if needed
                    if multi!=0:
                        newwalls.append(SDWall(currentn,point=self.point,d=multi,source=self));
            if self.exponents==(1,1):
                self.nexta=[];
                self.nextorder=100000;
            else:
                #removes the first entry in nexta, and generates a new entry with second coordinate 1 higher
                a=self.nexta.pop(0);
                a=(a[0],a[1]+1,a[2]+self.w2.order);
                #inserts the new entry so that they are ordered in lambda
                length=len(self.nexta);
                i=0;
                for i in range(1,len(self.nexta)+1):
                    if self.nexta[-i][2]<a[2]:
                        break
                    i=i+1
                self.nexta.insert(length-i+1,a);
                self.nextorder=self.nexta[0][2];
            return newwalls;

    def draw(self):
        """
            draw() returns a graphics object depicting the vertex, which is blue if the vertex is consistent and red otherwise
        """
        if self.nextorder>(100000-10):
            return point(self.point,marker='o',markeredgecolor='blue');
        else:
            return point(self.point,marker='o',markeredgecolor='red');

class ScatteringDiagram():
    """
        ScatteringDiagram(walls) creates an object which collects several walls into a scattering diagram.

        walls: a list of SDWalls comprising the scattering diagram

        Example:
        sage: ScatteringDiagram([SDWall((1,0)),SDWall((0,1)),SDWall((0,1),point=(0,-1))])
        A scattering diagram in R^2 with 3 walls and 2 vertices
    """

    def __init__(self,walls,table=DefaultTable):
        self.walls = walls;
        self.table = table;
        #the initial set of vertices are generated from the rays via pair-wise collision detection
        self.vertices =[];
        for i in range(0,len(self.walls)-1):
            for j in range(i+1,len(self.walls)):
                vert=self.walls[i].collide(self.walls[j],table=self.table);
                if vert!=None:
                    self.vertices.append(vert);
        #the order of the scattering diagrams is the minimum of the order of the vertices
        self.order = min([vert.nextorder-1 for vert in self.vertices]);
        #multiplicities is a dictionary which counts how many walls of type n the scattering diagram currently has
        self.multiplicities={};
        for wall in self.walls:
            if wall.n in self.multiplicities:
                self.multiplicities[wall.n]+=wall.d;
            else:
                self.multiplicities[wall.n]=wall.d;

    def __repr__(self):
        return "A scattering diagram in R^2 with "+str(len(self.walls))+" walls and "+str(len(self.vertices))+" vertices"

    def draw(self):
        """
            draw() produces a plot with all of the consituent walls and vertices, large enough to fit all of the vertices
        """
        #the lower right corner of the plot will be right and below each of the vertices
        xmin=min([vertex.point[0]-1 for vertex in self.vertices]);
        xmax=max([vertex.point[0]+1 for vertex in self.vertices]);
        ymin=min([vertex.point[1]-1 for vertex in self.vertices]);
        ymax=max([vertex.point[1]+1 for vertex in self.vertices]);
        return plot([vertex.draw() for vertex in self.vertices]+[wall.draw(xmin,xmax,ymin,ymax) for wall in self.walls],aspect_ratio=1,axes=False);

    def improve(self,verbose=False,draw=False):
        """
            improve() attempts to increases the order of the scattering diagram by 1
        """
        if self.order!=100000:
            for vertex in self.vertices:
                #use vertex.improve() to find rays that must be added at that vertex
                if vertex.nextorder==self.order+1:
                    newwalls=vertex.improve(verbose=verbose);
                    #check for collisions between new rays and old rays
                    for wall in newwalls:
                        for oldwall in self.walls:
                            vert=oldwall.collide(wall,table=self.table);
                            if vert !=None:
                                self.vertices.append(vert);
                    #add the new rays
                    self.walls.extend(newwalls);
                    #updates multiplicities
                    for wall in newwalls:
                        if wall.n in self.multiplicities:
                            self.multiplicities[wall.n]+=wall.d;
                        else:
                            self.multiplicities[wall.n]=wall.d;
            self.order=min([vert.nextorder for vert in self.vertices])-1;
            for v1 in self.vertices:
                for v2 in self.vertices:
                    if (v1.point==v2.point) and (v1!=v2):
                        print 'WARNING: A non-generic collision has occured at ' +str(v1.point)
        if draw:
            return self.draw()
︡bb6ff854-ebc3-473e-989e-22b420143452︡
︠d0fc569a-f4eb-45b6-a5eb-25c5182de982s︠
SDWall((0,1))
W=[SDWall((1,0)),SDWall((0,1)),SDWall((0,1),point=(0,-1))]
W
︡431ef2df-a50f-4bab-bdaf-e70b38051254︡{"stdout":"A line through the point (0, 0) with normal vector (0, 1)\n"}︡{"stdout":"[A line through the point (0, 0) with normal vector (1, 0), A line through the point (0, 0) with normal vector (0, 1), A line through the point (0, -1) with normal vector (0, 1)]\n"}︡
︠5365fc6c-bdc5-43a2-ac87-e5197c267f88s︠
D=ScatteringDiagram(W)
D
D.draw()
︡d2415007-9ddf-4af3-a2fd-a772845ee8cc︡{"stdout":"A scattering diagram in R^2 with 3 walls and 2 vertices\n"}︡{"once":false,"file":{"show":true,"uuid":"04cea8b1-d792-4c8d-88cb-92a90ee0e641","filename":"/projects/a377892b-9b6e-4a10-a2e1-c526b21c2e94/.sage/temp/compute1-us/24572/tmp_Wvf31L.svg"}}︡{"html":"<div align='center'></div>"}︡
︠5c3759dc-7e1a-487e-a0cc-feb42dd83569s︠
for i in range(2):
    D.improve(draw=True)
︡8ced9d00-9b98-4169-a10b-f14db410d563︡{"once":false,"file":{"show":true,"uuid":"4de2193c-8a1b-4a0d-956f-a1a83f073fc3","filename":"/projects/a377892b-9b6e-4a10-a2e1-c526b21c2e94/.sage/temp/compute1-us/24572/tmp_KcNYbH.svg"}}︡{"html":"<div align='center'></div>"}︡{"once":false,"file":{"show":true,"uuid":"f19c7fca-66d9-4906-bece-1d725551c7a8","filename":"/projects/a377892b-9b6e-4a10-a2e1-c526b21c2e94/.sage/temp/compute1-us/24572/tmp_iAa9iC.svg"}}︡{"html":"<div align='center'></div>"}︡
︠64be54dc-f3ee-4c04-bc43-72bfbf132da7s︠
D=ScatteringDiagram([SDWall((1,0)),SDWall((0,1)),SDWall((0,1),point=(0,-1)),SDWall((1,0),point=(2,0))])
D.draw()
for i in range(4):
    D.improve(draw=True)

︡55613bf5-d625-412f-a9fc-9ec06f31ec6e︡{"once":false,"file":{"show":true,"uuid":"6697e5b2-9ba3-441c-99ac-513dc39779a0","filename":"/projects/a377892b-9b6e-4a10-a2e1-c526b21c2e94/.sage/temp/compute1-us/24572/tmp_R6HiL8.svg"}}︡{"html":"<div align='center'></div>"}︡{"once":false,"file":{"show":true,"uuid":"520394fd-ce90-42c1-a08b-6bff4e2ef1c0","filename":"/projects/a377892b-9b6e-4a10-a2e1-c526b21c2e94/.sage/temp/compute1-us/24572/tmp_sA11u9.svg"}}︡{"html":"<div align='center'></div>"}︡{"once":false,"file":{"show":true,"uuid":"c7eca7a2-c5f2-495a-b2e1-90f011921864","filename":"/projects/a377892b-9b6e-4a10-a2e1-c526b21c2e94/.sage/temp/compute1-us/24572/tmp_44aIeL.svg"}}︡{"html":"<div align='center'></div>"}︡{"once":false,"file":{"show":true,"uuid":"997039d6-870a-4884-aa8d-0dd74b4698d6","filename":"/projects/a377892b-9b6e-4a10-a2e1-c526b21c2e94/.sage/temp/compute1-us/24572/tmp_OTf1QK.svg"}}︡{"html":"<div align='center'></div>"}︡{"once":false,"file":{"show":true,"uuid":"45457d1e-71d0-44d8-8620-4b9cf0e133d2","filename":"/projects/a377892b-9b6e-4a10-a2e1-c526b21c2e94/.sage/temp/compute1-us/24572/tmp_PDmYhO.svg"}}︡{"html":"<div align='center'></div>"}︡
︠20f39f1c-db12-4010-a2df-5088f9779bf0s︠
DefaultTable.diagrams[(2,2)].draw()
︡6f009cb6-c126-420a-8ddd-e3886b999c5f︡{"once":false,"file":{"show":true,"uuid":"2d18f724-e033-43a1-90ec-4fab0fd7dcbc","filename":"/projects/a377892b-9b6e-4a10-a2e1-c526b21c2e94/.sage/temp/compute1-us/24572/tmp_n2fLK3.svg"}}︡{"html":"<div align='center'></div>"}︡
︠8c3f5ad1-b105-48de-9803-26b5d4ddc882s︠
DefaultTable.mtable((2,2),16,verbose=True)
︡cee3601d-1c78-4267-8b6a-ae5e377aa8a9︡{"stdout":"Attempting to improve model (2, 2) to order 4\nModel (2, 2) improved to order 4\nAttempting to improve model (2, 2) to order 5\nModel (2, 2) improved to order 5\nAttempting to improve model (2, 2) to order 6\nModel (2, 2) improved to order 6\nAttempting to improve model (2, 2) to order 7\nModel (2, 2) improved to order 7\nAttempting to improve model (2, 2) to order 8\nModel (2, 2) improved to order 8\nAttempting to improve model (2, 2) to order 9\nModel (2, 2) improved to order 9\nAttempting to improve model (2, 2) to order 10\nModel (2, 2) improved to order 10\nAttempting to improve model (2, 2) to order 11\nModel (2, 2) improved to order 11\nAttempting to improve model (2, 2) to order 12\nModel (2, 2) improved to order 12\nAttempting to improve model (2, 2) to order 13\nModel (2, 2) improved to order 13\nAttempting to improve model (2, 2) to order 14\nModel (2, 2) improved to order 14\nAttempting to improve model (2, 2) to order 15\nModel (2, 2) improved to order 15\nAttempting to improve model (2, 2) to order 16\nModel (2, 2) improved to order 16\n[0]\n[0, 0]\n[0, 0, 0]\n[0, 0, 0, 0]\n[0, 0, 0, 0, 0]\n[0, 0, 0, 0, 0, 0]\n[0, 0, 0, 0, 0, 0, 0]\n[0, 0, 0, 0, 0, 0, 0, 0]\n[0, 0, 0, 0, 0, 0, 0, 2, 4]\n[0, 0, 0, 0, 0, 0, 2, 0, 2, 0]\n[0, 0, 0, 0, 0, 2, 0, 2, 0, 0, 0]\n[0, 0, 0, 0, 2, 0, 2, 0, 0, 0, 0, 0]\n[0, 0, 0, 2, 4, 2, 0, 0, 0, 0, 0, 0, 0]\n[0, 0, 2, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0]\n[0, 2, 4, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]\n[2, 4, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]\n[0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]\n"}︡
︠c3f891e9-4226-4b87-ad77-90c783daaa2ds︠
DefaultTable.diagrams[(2,2)].draw()
︡a7565480-cd25-4700-bdf6-31fe2de24097︡{"once":false,"file":{"show":true,"uuid":"771d2ffa-aa6a-4683-ad63-1e5fd332fcff","filename":"/projects/a377892b-9b6e-4a10-a2e1-c526b21c2e94/.sage/temp/compute1-us/24572/tmp_Fu_hW5.svg"}}︡{"html":"<div align='center'></div>"}︡
︠242fad72-4a8c-4e14-8af2-9b18f423c543s︠
DefaultTable.mtable((2,3),6,verbose=True)
︡de9337c6-4e9a-45a0-98c6-7e5dba7a1a75︡{"stdout":"Model (2, 3) created\nAttempting to improve model (2, 3) to order 2\nModel (2, 3) improved to order 2\nAttempting to improve model (2, 3) to order 3\nModel (2, 3) improved to order 3\nAttempting to improve model (2, 3) to order 4\nModel (1, 4) created\nAttempting to improve model (1, 4) to order 2\nModel (1, 4) improved to order 2\nAttempting to improve model (1, 4) to order 3\nModel (1, 3) created\nAttempting to improve model (1, 3) to order 2\nModel (1, 3) improved to order 2\nAttempting to improve model (1, 3) to order 3\nModel (1, 3) improved to order 3\nModel (1, 4) improved to order 3\nModel (2, 3) improved to order 4\nAttempting to improve model (2, 3) to order 5\nAttempting to improve model (1, 4) to order 4\nAttempting to improve model (1, 3) to order 4\nModel (1, 3) improved to order 4\nModel (1, 4) improved to order 4\nModel (2, 4) created\nAttempting to improve model (2, 4) to order 2\nModel (2, 4) improved to order 2\nAttempting to improve model (2, 4) to order 3\nModel (2, 4) improved to order 3\nModel (2, 3) improved to order 5\nAttempting to improve model (2, 3) to order 6\nAttempting to improve model (1, 4) to order 5\nAttempting to improve model (1, 3) to order 5\nModel (1, 3) improved to order 5\nModel (1, 4) improved to order 5\nAttempting to improve model (2, 4) to order 4\nModel (1, 6) created\nAttempting to improve model (1, 6) to order 2\nModel (1, 6) improved to order 2\nAttempting to improve model (1, 6) to order 3\nModel (1, 5) created\nAttempting to improve model (1, 5) to order 2\nModel (1, 5) improved to order 2\nAttempting to improve model (1, 5) to order 3\nModel (1, 5) improved to order 3\nModel (1, 6) improved to order 3\nModel (2, 4) improved to order 4\nModel (2, 3) improved to order 6\n[0]\n[0, 0]\n[0, 0, 0]\n[0, 0, 6, 18]\n[0, 3, 12, 14, 12]\n[2, 6, 6, 2, 0, 0]\n[0, 3, 0, 0, 0, 0, 0]\n"}︡
︠31c96504-b470-4261-b701-c8f514a4e248s︠
D=ScatteringDiagram([SDWall((1,0)),SDWall((0,1),point=(0,-1)),SDWall((0,1),point=(0,-3)),SDWall((0,1)),SDWall((1,0),point=(2.23,0)),SDWall((1,0),point=(5.3,0))])
D.draw()
for i in range(3):
    D.improve(verbose=True)
D.draw()
︡37c0a3a9-2016-4515-98aa-f9a9f40745b0︡{"once":false,"file":{"show":true,"uuid":"49d17bf2-7ef4-43e2-b3b6-6cbb00704076","filename":"/projects/a377892b-9b6e-4a10-a2e1-c526b21c2e94/.sage/temp/compute1-us/24572/tmp_mLkt7i.svg"}}︡{"html":"<div align='center'></div>"}︡{"once":false,"file":{"show":true,"uuid":"fbc7ded7-dfb1-43dd-a8fe-ec7231161e37","filename":"/projects/a377892b-9b6e-4a10-a2e1-c526b21c2e94/.sage/temp/compute1-us/24572/tmp_yDFsRb.svg"}}︡{"html":"<div align='center'></div>"}︡
︠f235ba42-418f-439f-be7f-6310ec80f223s︠
DefaultTable.mtable((3,3),8)
︡cf9ae76d-18d9-46cb-8ac5-648ea371ce9e︡{"stdout":"[0]"}︡{"stdout":"\n[0, 0]\n[0, 0, 0]\n[0, 0, 9, 204]\n[0, 0, 36, 204, 1044]\n[0, 3, 39, 162, 204, 204]\n[0, 9, 36, 39, 36, 9, 0]\n[3, 9, 9, 3, 0, 0, 0, 0]\n[0, 3, 0, 0, 0, 0, 0, 0, 0]\n"}︡
︠dbaebb57-d70d-4081-ace3-f58da2a3a722s︠
DefaultTable.diagrams[(3,3)].draw()
︡b66f6232-231b-4f8c-b299-f30a613cbcb1︡{"once":false,"file":{"show":true,"uuid":"3fd482e5-81f6-4fe0-a4bc-2eb2168c8796","filename":"/projects/a377892b-9b6e-4a10-a2e1-c526b21c2e94/.sage/temp/compute1-us/24572/tmp_jOSVPQ.svg"}}︡{"html":"<div align='center'></div>"}︡
︠4f894432-61d0-4459-bd9b-37070ad06f6bs︠
DefaultTable.GHKKTerm((2,2),(1,1))
DefaultTable.GHKKTerm((2,2),(1,1),denom=4)
DefaultTable.GHKKTerm((3,3),(1,1),denom=9)
︡5ec790cd-f533-47da-8cd7-1efdf19d091c︡{"stdout":"1 + 4*x + 10*x^2 + 20*x^3 + 35*x^4 + 56*x^5 + 84*x^6 + 120*x^7 + 165*x^8 + O(x^9)\n"}︡{"stdout":"1 + x + x^2 + x^3 + x^4 + x^5 + x^6 + x^7 + x^8 + O(x^9)\n"}︡{"stdout":"1 + x + 4*x^2 + 22*x^3 + 140*x^4 + O(x^5)\n"}︡
︠333ea194-a328-4980-9983-87b32c4b9c1c︠









