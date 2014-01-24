---
layout: post
title: "9种排序算法的java实现"
date: 2010-08-08 21:09:09 -0800
comments: true
categories: tech java 算法 代码
keywords: java 算法 代码
tags: java 算法
description: 
---
使用枚举类型存入各算法和接口实现，main方法打印排序后的数组，也可以加入nanotime、currentTimeMillis测试效率，但可能数组太小不明显

```java
package comcolalife.demo.sort;
import java.util.Arrays;
/**
 * 冒择入希快(快改进)归(归改进)堆：9种排序算法的java实现
 * @author wangchaoqun
 */
public class SortTest {
```
<!--more-->
```java
    public static void main(String[] args) {
		int[] original = { 1, 3, 1, 10, 4, 8, 5, 21, 43, 29, 53 };
		// 执行排序算法
		for (Sorts each : Sorts.values()) {
			System.out.print(each.name() + "	");
			int[] data = Arrays.copyOf(original, original.length);
			each.impl().sort(data);
			print(data);
		}
		// java.util.Arrays类使用调优的快速排序法
		Arrays.sort(original);
		print(original);
	}

	public static void print(int[] data) {
		for (int each : data) {
			System.out.print(each + " ");
		}
		System.out.println();
	}
}

/**
 * 插入排序算法
 */
class InsertSort implements Sort {
	public void sort(int[] data) {
		for (int i = 1; i < data.length; i++) {
			for (int j = i; (j > 0) && (data[j] < data[j - 1]); j--) {
				SortUtil.swap(data, j, j - 1);
			}
		}
	}
}

/**
 * 冒泡排序算法
 */
class BubbleSort implements Sort {
	public void sort(int[] data) {
		for (int i = 0; i < data.length; i++) {
			for (int j = data.length - 1; j > i; j--) {
				if (data[j] < data[j - 1]) {
					SortUtil.swap(data, j, j - 1);
				}
			}
		}
	}

}

/**
 * 选择排序算法
 */
class SelectionSort implements Sort {
	public void sort(int[] data) {
		for (int i = 0; i < data.length; i++) {
			int lowIndex = i;
			for (int j = data.length - 1; j > i; j--) {
				if (data[j] < data[lowIndex]) {
					lowIndex = j;
				}
			}
			SortUtil.swap(data, i, lowIndex);
		}
	}

}

/**
 * 希尔排序算法
 */
class ShellSort implements Sort {
	public void sort(int[] data) {
		for (int i = data.length / 2; i > 2; i /= 2) {
			for (int j = 0; j < i; j++) {
				insertSort(data, j, i);
			}
		}
		insertSort(data, 0, 1);
	}

	private void insertSort(int[] data, int start, int inc) {
		for (int i = start + inc; i < data.length; i += inc) {
			for (int j = i; (j >= inc) && (data[j] < data[j - inc]); j -= inc) {
				SortUtil.swap(data, j, j - inc);
			}
		}
	}

}

/**
 * 快速排序算法
 */
class QuickSort implements Sort {
	public void sort(int[] data) {
		quickSort(data, 0, data.length - 1);
	}

	private void quickSort(int[] data, int first, int last) {
		if (first >= last) {
			return;
		}

		int pivot = partition(data, first, last, first);
		quickSort(data, first, pivot - 1);// 对左半段排序
		quickSort(data, pivot + 1, last);// 对右半段排序

	}

	private int partition(int[] data, int first, int last, int pivot) {
		while (true) {
			while (data[++first] < data[pivot])
				;
			while (data[--last] > data[pivot])
				;
			if (first >= last) {
				break;
			}
			SortUtil.swap(data, first, last);
		}
		SortUtil.swap(data, last, pivot);
		return last;
	}

}

/**
 * 改进的快速排序算法
 */
class ImprovedQuickSort implements Sort {
	private static int MAX_STACK_SIZE = 4096;
	private static int THRESHOLD = 10;

	public void sort(int[] data) {
		int[] stack = new int[MAX_STACK_SIZE];

		int top = -1;
		int pivot;
		int pivotIndex, l, r;

		stack[++top] = 0;
		stack[++top] = data.length - 1;

		while (top > 0) {
			int j = stack[top--];
			int i = stack[top--];

			pivotIndex = (i + j) / 2;
			pivot = data[pivotIndex];

			SortUtil.swap(data, pivotIndex, j);

			// partition
			l = i - 1;
			r = j;
			do {
				while (data[++l] < pivot)
					;
				while ((r != 0) && (data[--r] > pivot))
					;
				SortUtil.swap(data, l, r);
			} while (l < r);
			SortUtil.swap(data, l, r);
			SortUtil.swap(data, l, j);

			if ((l - i) > THRESHOLD) {
				stack[++top] = i;
				stack[++top] = l - 1;
			}
			if ((j - l) > THRESHOLD) {
				stack[++top] = l + 1;
				stack[++top] = j;
			}
		}
		insertSort(data);
	}

	private void insertSort(int[] data) {
		for (int i = 1; i < data.length; i++) {
			for (int j = i; (j > 0) && (data[j] < data[j - 1]); j--) {
				SortUtil.swap(data, j, j - 1);
			}
		}
	}

}

/**
 * 归并排序算法
 */
class MergeSort implements Sort {
	public void sort(int[] data) {
		int[] temp = new int[data.length];
		mergeSort(data, temp, 0, data.length - 1);
	}

	private void mergeSort(int[] data, int[] temp, int left, int right) {
		if (left == right) {
			return;
		}
		int mid = (left + right) / 2;
		mergeSort(data, temp, left, mid);
		mergeSort(data, temp, mid + 1, right);
		for (int i = left; i <= right; i++) {
			temp = Arrays.copyOf(data, data.length);
		}
		int i1 = left;
		int i2 = mid + 1;
		for (int cur = left; cur <= right; cur++) {
			if (i1 == mid + 1) {
				data[cur] = temp[i2++];
			} else if (i2 > right) {
				data[cur] = temp[i1++];
			} else if (temp[i1] < temp[i2]) {
				data[cur] = temp[i1++];
			} else {
				data[cur] = temp[i2++];
			}
		}
	}

}

/**
 * 改进的归并排序算法
 */
class ImprovedMergeSort implements Sort {
	private static final int THRESHOLD = 10;

	public void sort(int[] data) {
		int[] temp = new int[data.length];
		mergeSort(data, temp, 0, data.length - 1);
	}

	private void mergeSort(int[] data, int[] temp, int left, int right) {
		int i, j, k;
		int mid = (left + right) / 2;
		if (left == right) {
			return;
		}
		if ((mid - left) >= THRESHOLD) {
			mergeSort(data, temp, left, mid);
		} else {
			insertSort(data, left, mid - left + 1);
		}
		if ((right - mid) > THRESHOLD) {
			mergeSort(data, temp, mid + 1, right);
		} else {
			insertSort(data, mid + 1, right - mid);
		}
		for (i = left; i <= mid; i++) {
			temp = Arrays.copyOf(data, data.length);
		}
		for (j = 1; j <= right - mid; j++) {
			temp[right - j + 1] = data[j + mid];
		}
		int a = temp[left];
		int b = temp[right];
		for (i = left, j = right, k = left; k <= right; k++) {
			if (a < b) {
				data[k] = temp[i++];
				a = temp[i];
			} else {
				data[k] = temp[j--];
				b = temp[j];
			}
		}
	}

	private void insertSort(int[] data, int start, int len) {
		for (int i = start + 1; i < start + len; i++) {
			for (int j = i; (j > start) && data[j] < data[j - 1]; j--) {
				SortUtil.swap(data, j, j - 1);
			}
		}
	}

}

/**
 * 堆排序算法
 */
class HeapSort implements Sort {
	public void sort(int[] data) {
		MaxHeap h = new MaxHeap();
		h.init(data);
		for (int i = 0; i < data.length; i++) {
			h.remove();
		}
		System.arraycopy(h.queue, 1, data, 0, data.length);
	}

	private static class MaxHeap {
		void init(int[] data) {
			this.queue = new int[data.length + 1];
			for (int i = 0; i < data.length; i++) {
				queue[++size] = data[i];
				fixUp(size);
			}
		}

		private int size = 0;
		private int[] queue;

		public void remove() {
			SortUtil.swap(queue, 1, size--);
			fixDown(1);
		}

		// fixdown
		private void fixDown(int k) {
			int j;
			while ((j = k << 1) <= size) {
				if (j < size && queue[j] < queue[j + 1]) {
					j++;
				}
				if (queue[k] > queue[j]) { // 不用交换
					break;
				}
				SortUtil.swap(queue, j, k);
				k = j;
			}
		}

		private void fixUp(int k) {
			while (k > 1) {
				int j = k >> 1;
				if (queue[j] > queue[k]) {
					break;
				}
				SortUtil.swap(queue, j, k);
				k = j;
			}
		}

	}

}

/**
 * 排序算法接口
 */
interface Sort {
	public void sort(int[] data);
}

/**
 * 排序算法枚举
 */
enum Sorts {
	INSERT() {
		public Sort impl() {
			return new InsertSort();
		}
	},
	BUBBLE() {
		public Sort impl() {
			return new BubbleSort();
		}
	},
	SELECTION() {
		public Sort impl() {
			return new SelectionSort();
		}
	},
	SHELL() {
		public Sort impl() {
			return new ShellSort();
		}
	},
	QUICK() {
		public Sort impl() {
			return new QuickSort();
		}
	},
	IMPROVED_QUICK() {
		public Sort impl() {
			return new ImprovedQuickSort();
		}
	},
	MERGE() {
		public Sort impl() {
			return new MergeSort();
		}
	},
	IMPROVED_MERGE() {
		public Sort impl() {
			return new ImprovedMergeSort();
		}
	},
	HEAP() {
		public Sort impl() {
			return new HeapSort();
		}
	};

	public abstract Sort impl();
}

/**
 * 排序算法工具类
 */
class SortUtil {
	public static void swap(int[] data, int i, int j) {
		int temp = data[i];
		data[i] = data[j];
		data[j] = temp;
	}
	
	public static void print(int[] data) {
		for (int each : data) {
			System.out.print(each + " ");
		}
		System.out.println();
	}
}




```
