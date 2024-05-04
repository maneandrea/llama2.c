#define PY_SSIZE_T_CLEAN

#include <Python.h>
#include <stdio.h>

#include "run.c"


struct vector {
    double *addr;
    Py_ssize_t len;
};


static int list_converter(PyObject *object, struct vector *address)
{
    if (!PyList_Check(object)) {
        PyErr_SetString(PyExc_TypeError, "passed argument is not a list");
        return 0;
    }

    const Py_ssize_t s = PyList_Size(object);

    Py_ssize_t i;
    PyObject *elt = NULL;
    double *tmp_address = malloc(sizeof(float) * s);

    for (i = 0; i < s; i++) {
        elt = PyList_GetItem(object, i);
        if (elt == NULL) {
            return 0;
        }
        if (!PyFloat_Check(elt)) {
           PyErr_SetString(PyExc_TypeError, "list element is not a float");
           return 0;
        }
        tmp_address[i] = PyFloat_AsDouble(elt);
    }
    address->addr = tmp_address;
    address->len = s;
    return 1;
}

static double dotprod(double* x, double* y, int d)
{
    // x (d,) @ y (d,) -> xout (scalar)
    int i;
    float val = 0.0f;
    for (i = 0; i < d; i++) {
        val += x[i] * y[i];
    }
    return val;
}


static PyObject *py_matmul(PyObject *self, PyObject *args)
{
    const struct vector x = {NULL, 0};
    const struct vector w = {NULL, 0};


    if (!PyArg_ParseTuple(args, "O&O&", list_converter, &x, list_converter, &w)) {
        return NULL;
    }

    if (x.addr != NULL && w.addr != NULL) {
        if (x.len == w.len) {
            Py_ssize_t j;
            double out = dotprod(x.addr, w.addr, (int) x.len);
            return Py_BuildValue("d", out);
        } else {
            PyErr_SetString(PyExc_ValueError, "vectors must be of the same size");
            return NULL;
        }
    } else {
        PyErr_SetString(PyExc_TypeError, "error in parsing arguments");
        return NULL;
    }

}

static PyMethodDef LlamaMethods[] = {
    {"matmul",  py_matmul, METH_VARARGS | METH_KEYWORDS, "Multiply a matrix by a vector."},
    {NULL, NULL, 0, NULL}        /* Sentinel */
};

static struct PyModuleDef llamamodule = {
    PyModuleDef_HEAD_INIT,
    "llama",   /* name of module */
    NULL,      /* module documentation, may be NULL */
    -1,        /* size of per-interpreter state of the module,
                  or -1 if the module keeps state in global variables. */
    LlamaMethods
};

PyMODINIT_FUNC PyInit_llama(void)
{
    return PyModule_Create(&llamamodule);
}