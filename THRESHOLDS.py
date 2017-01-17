import sys, os, glob
import matplotlib
matplotlib.use('Qt5Agg') 
from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg as FigureCanvas
import matplotlib.pylab as plt
from PyQt5 import QtGui, QtWidgets, QtCore
import numpy as np
import time
ROOT_PATH = 'D:'+os.path.sep+'yann'+os.path.sep
from sklearn.mixture import GaussianMixture

def get_last_bin_file(dir='./'):
    """ get lastly created bin file """
    FILES = glob.glob(dir+os.path.sep+'*.bin')
    FILES.sort(key=lambda x: os.path.getmtime(x))
    print(FILES)
    return FILES[-1]

def load_file(filename, zoom=30):
    dt = 1e-4 # acquisition frequency 10kHz
    data = np.fromfile(filename, dtype=np.float32)
    return data[-int(zoom/dt):]

def fit_gaussians(Vm, weights, means,
                  n=1000, ninit=20, bound1=-90, bound2=-35):
    clf = GaussianMixture(n_components=3, max_iter=n, n_init=ninit,
            means_init=((means[0],), (means[1],), (means[2],)),
                          covariance_type='spherical', tol=1e-4)
    clf.fit(np.array((Vm[(Vm>bound1) & (Vm<bound2)],)).T)
    return clf.weights_, clf.means_.flatten(), np.sqrt(clf.covariances_)

def determine_thresholds(weights, means, stds):
    """ Gives the thresholds given the Gaussian Mixture"""
    i0, i1 = np.argmin(means[0:2]), np.argmax(means[1:3])+1
    alpha = 1.-np.exp(-hvsd(means[i1]-2.*stds[i1]-means[i0]-2.*stds[i0])/5.)
    return means[i0]+2.*alpha*stds[i0], means[i1]-2.*alpha*stds[i1]

def hvsd(x):
    return .5*(1.+np.sign(x))*x

def Gaussian(X, m, s):
    Y = np.exp(-(X-m)**2/2./s**2)
    return Y/Y.sum()
    
class Window(QtWidgets.QMainWindow):
    """ subclassing QtWidgets.QMainWindow """
    def __init__(self, parent=None):
        """ """
        super(Window, self).__init__(parent)
        # buttons and functions
        LABELS = ["q) Quit", "o) Open File", "f) Set Folder", "p) Plot"]
        FUNCTIONS = [self.close_app, self.file_open, self.folder_open, self.plot]
        button_length = 113.
        self.setWindowTitle('Up and Down states thresholds')
        self.setGeometry(50, 50, button_length*(len(LABELS)), 90)

        mainMenu = self.menuBar()
        self.fileMenu = mainMenu.addMenu('&File')
        for func, label, hshift in zip(FUNCTIONS, LABELS, button_length*np.arange(len(LABELS))):
            btn = QtWidgets.QPushButton(label, self)
            btn.clicked.connect(func)
            btn.setMinimumWidth(button_length)
            btn.move(hshift, 0)
            action = QtWidgets.QAction(label, self)
            action.setShortcut(label.split(')')[0])
            action.triggered.connect(func)
            self.fileMenu.addAction(action)
            
        label, func = "c) ========  Calculate ========", self.analyze
        btn = QtWidgets.QPushButton(label, self)
        btn.clicked.connect(func)
        btn.setMinimumWidth(button_length*(len(LABELS)))
        btn.setMinimumHeight(40)
        btn.move(0, 30)
        action = QtWidgets.QAction(label, self)
        action.setShortcut(label.split(')')[0])
        action.triggered.connect(func)
        self.fileMenu.addAction(action)
        # default folder
        self.folder = ROOT_PATH+'DATA_elphy'+os.path.sep+time.strftime("%Y_")+\
                      str(int(time.strftime("%m")))+"_"+str(int(time.strftime("%d")))
        print(self.folder)
        if not os.path.exists(self.folder):
            self.folder = ROOT_PATH+'DATA_elphy'
        self.force_file = False # by default will be last generated file

        # default values
        self.means = [-85, -65, -50]
        self.weights = [0.4, 0.3, 0.3]
        self.stds = [0.5, 3., 3.]
        
        self.show()

    def analyze(self):
        if not self.force_file:
            self.filename = get_last_bin_file(self.folder)
        self.statusBar().showMessage('Analyzing Datafile: '+self.filename.split(os.path.sep)[-1])
        Vm = load_file(self.filename)
        self.weights, self.means, self.stds = fit_gaussians(Vm, self.weights, self.means)
        threshold1, threshold2 = determine_thresholds(self.weights, self.means, self.stds)
        ff = open(self.folder+os.path.sep+'thresholds.txt', 'w')
        ff.write(str(threshold1)+'\n'+str(threshold2))
        ff.close()
        self.statusBar().showMessage('Vth1='+str(int(threshold1))+', Vth2='+str(int(threshold2)))
        self.force_file = False
    
    def close_app(self):
        sys.exit()

    def file_open(self):
        name=QtWidgets.QFileDialog.getOpenFileName(self, 'Open File',\
                                                   self.folder)
        if name[0]!='':
            self.force_file = True
            self.filename = name[0]
            self.statusBar().showMessage('Datafile will be: '+name[0].split(os.path.sep)[-1])

    def folder_open(self):
        name=QtWidgets.QFileDialog.getExistingDirectory(self, 'Select Folder', self.folder)
        if name!='':
            self.folder = name

    def plot(self):
        if not self.force_file:
            self.filename = get_last_bin_file(self.folder)
        self.statusBar().showMessage('Analyzing Datafile: '+self.filename.split(os.path.sep)[-1])
        fig, ax = plt.subplots()
        Vm = load_file(self.filename)
        hist, BE = np.histogram(Vm, bins=np.linspace(-85, -30, 100))
        ax.bar(.5*(BE[:-1]+BE[1:]), hist*1.0/hist.sum(), color='gray', lw=0, width=BE[1]-BE[0])
        for w, m, s in zip(self.weights, self.means, self.stds):
            ax.plot(.5*(BE[:-1]+BE[1:]), w*Gaussian(.5*(BE[:-1]+BE[1:]), m, s), lw=2)
        plt.draw()
        plt.pause(4)
        plt.close(fig)

if __name__ == '__main__':
    app = QtWidgets.QApplication(sys.argv)
    main = Window()
    main.show()
    sys.exit(app.exec_())
